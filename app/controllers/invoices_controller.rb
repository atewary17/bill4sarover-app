class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show]

  def index
    @invoices = Invoice.order(created_at: :desc)
  end

  def new
    @invoice = Invoice.new
    @bookings = Booking.where(id: params[:booking_ids])
                       .where.not(status: :invoiced) # Prevent re-invoicing
    
    # Alert if trying to invoice already-invoiced bookings
    if @bookings.empty? && params[:booking_ids].present?
      redirect_to bookings_path, alert: "Selected bookings are already invoiced"
      return
    end
    
    @customers = if @bookings.any?
      (
        @bookings.map(&:customer) +
        @bookings.map { |b| b.customer&.payer }.compact
      ).uniq
    else
      Customer.order(:name)
    end
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.invoice_number = generate_invoice_number
    @invoice.status         = "draft"

    # Populate billed_to fields from selected customer
    resolve_billed_to

    build_booking_items
    build_extra_items
    build_adhoc_items
    calculate_totals

    begin
      ActiveRecord::Base.transaction do
        # Save invoice and all invoice_items
        @invoice.save!
        
        # Link bookings to invoice
        link_bookings_to_invoice
        
        # Mark bookings as invoiced
        mark_bookings_as_invoiced
      end
      
      redirect_to @invoice, notice: "Invoice created successfully"
      
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Invoice creation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Rebuild form data for re-render
      @bookings = Booking.where(id: params[:booking_ids])
                         .where.not(status: :invoiced)
      @customers = if @bookings.any?
        (
          @bookings.map(&:customer) +
          @bookings.map { |b| b.customer&.payer }.compact
        ).uniq
      else
        Customer.order(:name)
      end
      
      # Add error to invoice
      @invoice.errors.add(:base, "Failed to create invoice: #{e.message}")
      render :new, status: :unprocessable_entity
      
    rescue StandardError => e
      Rails.logger.error "Unexpected error during invoice creation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Rebuild form data
      @bookings = Booking.where(id: params[:booking_ids])
                         .where.not(status: :invoiced)
      @customers = if @bookings.any?
        (
          @bookings.map(&:customer) +
          @bookings.map { |b| b.customer&.payer }.compact
        ).uniq
      else
        Customer.order(:name)
      end
      
      @invoice.errors.add(:base, "An unexpected error occurred. Please try again.")
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:invoice_items, :bookings).find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :billed_to_id,
      :billed_to_type,
      :billed_to_name,
      :billed_to_phone,
      :billed_to_email,
      :company_gst_number,
      :discount_type,
      :discount_value,
      :tax_rate,
      :due_date,
      :issued_at,
      :notes,
      :terms_and_conditions
    )
  end

  # Populate billed_to fields from selected customer
  def resolve_billed_to
    return unless @invoice.billed_to_id.present?

    customer = Customer.find_by(id: @invoice.billed_to_id)
    return unless customer

    @invoice.billed_to_type  = "Customer"
    @invoice.billed_to_name  = customer.name
    @invoice.billed_to_phone = @invoice.billed_to_phone.presence || customer.phone
    @invoice.billed_to_email = @invoice.billed_to_email.presence || customer.email
  end

  # Build invoice items from selected booking_ids
  def build_booking_items
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
      
      # Skip if already invoiced
      next if booking.invoiced?

      nights     = ((booking.check_out - booking.check_in) / 1.day).to_i
      unit_price = booking.room&.rate || 0
      gross      = nights * unit_price

      @invoice.invoice_items.build(
        description:  "Room #{booking.room&.room_number} - #{booking.room&.room_type}",
        quantity:     nights,
        unit_price:   unit_price,
        gross_amount: gross,
        line_total:   gross,
        source_type:  "Booking",
        source_id:    booking.id,
        metadata:     {
          type:        "booking",
          room_number: booking.room&.room_number,
          room_type:   booking.room&.room_type,
          check_in:    booking.check_in,
          check_out:   booking.check_out,
          customer:    booking.customer&.name
        }
      )
    end
  end

  # Service charges tied to a specific booking
  def build_extra_items
    return unless params[:extra_items].present?

    params[:extra_items].each_value do |item|
      next if item[:description].blank? && item[:unit_price].blank?

      qty        = item[:quantity].to_d
      unit_price = item[:unit_price].to_d
      gross      = qty * unit_price

      @invoice.invoice_items.build(
        description:  item[:description],
        quantity:     qty,
        unit_price:   unit_price,
        gross_amount: gross,
        line_total:   gross,
        source_type:  "Booking",
        source_id:    item[:booking_id],
        metadata:     {
          type:       "service_charge",
          booking_id: item[:booking_id]
        }
      )
    end
  end

  # Standalone adhoc items not tied to any booking
  def build_adhoc_items
    return unless params[:adhoc_items].present?

    params[:adhoc_items].each_value do |item|
      next if item[:description].blank? && item[:unit_price].blank?

      qty        = item[:quantity].to_d
      unit_price = item[:unit_price].to_d
      gross      = qty * unit_price

      @invoice.invoice_items.build(
        description:  item[:description],
        quantity:     qty,
        unit_price:   unit_price,
        gross_amount: gross,
        line_total:   gross,
        source_type:  nil,
        source_id:    nil,
        metadata:     {
          type: "adhoc"
        }
      )
    end
  end

  # Calculate and assign all totals on invoice and each item
  def calculate_totals
    subtotal  = 0
    tax_total = 0

    @invoice.invoice_items.each do |item|
      gross    = item.quantity.to_d * item.unit_price.to_d
      tax_rate = @invoice.tax_rate.to_d
      tax      = gross * (tax_rate / 100)

      item.gross_amount         = gross
      item.line_discount_type   = nil
      item.line_discount_value  = 0
      item.line_discount_amount = 0
      item.tax_rate             = tax_rate
      item.tax_amount           = tax
      item.line_total           = gross + tax

      subtotal  += gross
      tax_total += tax
    end

    # Invoice-level discount applied on subtotal
    invoice_discount =
      if @invoice.discount_type == "percentage"
        subtotal * @invoice.discount_value.to_d / 100
      else
        @invoice.discount_value.to_d
      end

    @invoice.subtotal        = subtotal
    @invoice.discount_amount = invoice_discount
    @invoice.taxable_amount  = subtotal - invoice_discount
    @invoice.tax_amount      = tax_total
    @invoice.total_amount    = @invoice.taxable_amount + tax_total
  end

  # Link selected bookings to the invoice via invoice_bookings join table
  def link_bookings_to_invoice
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
      next if booking.invoiced? # Skip already invoiced bookings
      
      @invoice.bookings << booking unless @invoice.bookings.include?(booking)
    end
  end

  # Mark all linked bookings as invoiced
  def mark_bookings_as_invoiced
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
      
      # Use invoiced! method (clearest and most concise)
      booking.invoiced! unless booking.invoiced?
    end
  end

  def generate_invoice_number
    "SAR-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end