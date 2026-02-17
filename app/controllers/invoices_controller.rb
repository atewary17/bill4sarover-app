class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show]

  def index
    @invoices = Invoice.order(created_at: :desc)
  end

  def new
    @invoice = Invoice.new
    @bookings = Booking.where(id: params[:booking_ids])
    @customers = (
      @bookings.map(&:customer) +
      @bookings.map { |b| b.customer&.payer }.compact
    ).uniq
  end

  def create
    puts "......................1"
    puts params
    puts "......................2"
    puts invoice_params
    @invoice = Invoice.new(invoice_params)
    puts ".....................w"
    puts @invoice.billed_to_id
    @invoice.invoice_number = generate_invoice_number
    @invoice.status         = "draft"

    build_booking_items
    build_extra_items
    calculate_totals

    if @invoice.save
      link_bookings_to_invoice
      redirect_to @invoice, notice: "Invoice created successfully"
    else
      @bookings = Booking.where(id: params[:booking_ids])
      @customers = (
        @bookings.map(&:customer) +
        @bookings.map { |b| b.customer&.payer }.compact
      ).uniq
      render :new, status: :unprocessable_entity
    end
    puts ".....................4"
    puts @invoice.billed_to_id
  end

  def show
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:invoice_items).find(params[:id])
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

  # Build invoice items from selected booking_ids
  def build_booking_items
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking

      nights     = ((booking.check_out - booking.check_in) / 1.day).to_i
      unit_price = booking.room&.rate || 0
      gross      = nights * unit_price

      @invoice.invoice_items.build(
        description:    "Room #{booking.room&.room_number} - #{booking.room&.room_type}",
        quantity:       nights,
        unit_price:     unit_price,
        gross_amount:   gross,
        line_total:     gross,   # no line discount, calculated later
        source_type:    "Booking",
        source_id:      booking.id,
        metadata:       {
          room_number: booking.room&.room_number,
          room_type:   booking.room&.room_type,
          check_in:    booking.check_in,
          check_out:   booking.check_out,
          customer:    booking.customer&.name
        }
      )
    end
  end

  # Build invoice items from extra service charges added in the form
  def build_extra_items
    return unless params[:extra_items].present?

    params[:extra_items].each_value do |item|
      next if item[:description].blank? && item[:unit_price].blank?

      booking_id = item[:booking_id]
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
        source_id:    booking_id,
        metadata:     {
          type:       "service_charge",
          booking_id: booking_id
        }
      )
    end
  end

  # Calculate and assign all totals on invoice and each item
  def calculate_totals
    subtotal  = 0
    tax_total = 0

    @invoice.invoice_items.each do |item|
      gross = item.quantity.to_d * item.unit_price.to_d

      # No line-level discount (removed from UI)
      taxable    = gross
      tax_rate   = @invoice.tax_rate.to_d
      tax        = taxable * (tax_rate / 100)

      item.gross_amount        = gross
      item.line_discount_type  = nil
      item.line_discount_value = 0
      item.line_discount_amount = 0
      item.tax_rate            = tax_rate
      item.tax_amount          = tax
      item.line_total          = taxable + tax

      subtotal  += taxable
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
      @invoice.bookings << booking unless @invoice.bookings.include?(booking)
    end
  end

  def generate_invoice_number
    "SAR-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end