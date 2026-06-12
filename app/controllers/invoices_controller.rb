class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :mark_paid, :mark_void, :issue, :record_payment, :download_pdf, :download_receipt]

  def index
    @from = params[:from].presence&.to_date || 10.days.ago.to_date
    @to   = params[:to].presence&.to_date || 10.days.from_now.to_date

    @invoices = Invoice.includes(:invoice_items, :bookings)
                       .where("created_at >= ? AND created_at <= ?", 
                              @from.beginning_of_day, 
                              @to.end_of_day)
                       .order(created_at: :desc)
  end

  def new
    @invoice = Invoice.new
    @suggested_invoice_number = suggested_invoice_number
    @bookings = Booking.where(id: params[:booking_ids])
                       .where.not(status: :invoiced)
    
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
    @invoice.status = "draft"

    resolve_billed_to

    build_booking_items
    build_extra_items
    build_adhoc_items
    calculate_totals

    begin
      ActiveRecord::Base.transaction do
        @invoice.save!
        link_bookings_to_invoice
        mark_bookings_as_invoiced
      end
      
      redirect_to @invoice, notice: "Invoice created successfully"
      
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Invoice creation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
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
      
      @invoice.errors.add(:base, "Failed to create invoice: #{e.message}")
      render :new, status: :unprocessable_entity
      
    rescue StandardError => e
      Rails.logger.error "Unexpected error during invoice creation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
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
    @payments   = @invoice.payments.order(created_at: :desc)
    @total_paid = @payments.sum(:amount)
    @balance_due = @invoice.total_amount - @total_paid

    # Derive guest company: manual entry takes precedence, then payer lookup
    @guest_company = @invoice.guest_company.presence
    if @guest_company.nil? && @invoice.billed_to_id.present?
      billed_customer = Customer.find_by(id: @invoice.billed_to_id)
      payer = billed_customer&.payer
      @guest_company = payer.name if payer&.is_company?
    end
  end

  def edit
    @customers = Customer.order(:name)
  end

  def update
    ActiveRecord::Base.transaction do
      @invoice.assign_attributes(invoice_update_params)
      tag_new_adhoc_items
      calculate_totals
      @invoice.save!
    end

    redirect_to @invoice, notice: "Invoice updated successfully"

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Invoice update failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    @customers = Customer.order(:name)
    @invoice.errors.add(:base, "Failed to update invoice: #{e.message}") if @invoice.errors.empty?
    render :edit, status: :unprocessable_entity
  end

  # Mark invoice as issued
  def issue
    if @invoice.draft?
      append_note("Invoice issued on #{Time.current.strftime('%d %b %Y at %H:%M')}")
      @invoice.update!(status: :issued, issued_at: Time.current)
      redirect_to @invoice, notice: "Invoice issued successfully"
    else
      redirect_to @invoice, alert: "Invoice cannot be issued from #{@invoice.status} status"
    end
  end

  # Record partial payment
  def record_payment
    amount = params[:amount].to_d
    payment_note = params[:payment_note]

    if amount <= 0
      redirect_to @invoice, alert: "Payment amount must be greater than zero"
      return
    end

    total_paid = @invoice.payments.sum(:amount)
    remaining = @invoice.total_amount - total_paid

    if amount > remaining
      redirect_to @invoice, alert: "Payment amount exceeds balance due"
      return
    end

    ActiveRecord::Base.transaction do
      # Create payment record
      payment = @invoice.payments.create!(
        amount: amount,
        payment_method: params[:payment_method] || "cash",
        reference_number: params[:reference_number],
        payment_note: payment_note,
        paid_at: Time.current
      )

      # Update invoice status
      new_total_paid = total_paid + amount
      if new_total_paid >= @invoice.total_amount
        @invoice.update!(status: :paid)
        append_note("Fully paid on #{Time.current.strftime('%d %b %Y at %H:%M')} - Rs #{amount}")
      else
        @invoice.update!(status: :partial)
        append_note("Partial payment on #{Time.current.strftime('%d %b %Y at %H:%M')} - Rs #{amount}")
      end

      # Store payment ID in flash for JavaScript to use
      flash[:payment_id] = payment.id
      flash[:notice] = "Payment recorded successfully"
      
      redirect_to @invoice
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @invoice, alert: "Failed to record payment: #{e.message}"
  end

  # Mark invoice as paid
  def mark_paid
    if @invoice.paid?
      redirect_to @invoice, alert: "Invoice is already paid"
      return
    end

    amount = params[:amount].to_d
    payment_note = params[:note]

    if amount <= 0
      amount = @invoice.total_amount - @invoice.payments.sum(:amount)
    end

    ActiveRecord::Base.transaction do
      payment = @invoice.payments.create!(
        amount: amount,
        payment_method: params[:payment_method] || "cash",
        reference_number: params[:reference_number],
        payment_note: payment_note,
        paid_at: Time.current
      )

      append_note("Marked as paid on #{Time.current.strftime('%d %b %Y at %H:%M')}")
      append_note("Payment note: #{payment_note}") if payment_note.present?
      
      @invoice.update!(status: :paid)

      # Store payment ID in flash
      flash[:payment_id] = payment.id
      flash[:notice] = "Invoice marked as paid"
      
      redirect_to @invoice
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @invoice, alert: "Failed to mark as paid: #{e.message}"
  end

  # Mark invoice as void
  def mark_void
    if @invoice.void?
      redirect_to @invoice, alert: "Invoice is already void"
      return
    end

    void_reason = params[:void_reason]
    
    if void_reason.blank?
      redirect_to @invoice, alert: "Please provide a reason for voiding the invoice"
      return
    end

    append_note("Voided on #{Time.current.strftime('%d %b %Y at %H:%M')}")
    append_note("Void reason: #{void_reason}")
    
    @invoice.update!(status: :void)
    redirect_to @invoice, notice: "Invoice marked as void"
  end

  # Download invoice PDF
  def download_pdf
    pdf = InvoicePdf.new(@invoice)
    send_data pdf.render,
              filename: "invoice_#{@invoice.invoice_number}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  # Download receipt PDF
  def download_receipt
    payment = @invoice.payments.find_by(id: params[:payment_id]) || @invoice.payments.last
    
    if payment.nil?
      redirect_to @invoice, alert: "No payment found"
      return
    end
    
    pdf = ReceiptPdf.new(@invoice, payment)
    send_data pdf.render,
              filename: "receipt_#{@invoice.invoice_number}_#{payment.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:invoice_items, :bookings, :payments).find(params[:id])
  end

  def append_note(new_note)
    if @invoice.notes.present?
      @invoice.notes += "\n-----\n#{new_note}"
    else
      @invoice.notes = new_note
    end
    @invoice.save!
  end

  def invoice_params
    params.require(:invoice).permit(
      :invoice_number,
      :billed_to_id,
      :billed_to_type,
      :billed_to_name,
      :billed_to_phone,
      :billed_to_email,
      :company_gst_number,
      :guest_name,
      :guest_company,
      :discount_type,
      :discount_value,
      :tax_rate,
      :due_date,
      :issued_at,
      :notes,
      :terms_and_conditions
    )
  end

  def invoice_update_params
    params.require(:invoice).permit(
      :invoice_number,
      :billed_to_name,
      :billed_to_phone,
      :billed_to_email,
      :company_gst_number,
      :guest_name,
      :guest_company,
      :discount_type,
      :discount_value,
      :tax_rate,
      :status,
      :due_date,
      :issued_at,
      :notes,
      :terms_and_conditions,
      invoice_items_attributes: [
        :id,
        :description,
        :quantity,
        :unit_price,
        :_destroy
      ]
    )
  end

  # New line items added through the edit form have no metadata; treat them as
  # adhoc (no GST) so they render and tax correctly. Existing items keep theirs.
  def tag_new_adhoc_items
    @invoice.invoice_items.each do |item|
      next if item.marked_for_destruction?
      next if item.metadata&.dig("type").present?

      item.metadata = { "type" => "adhoc" }
    end
  end

  def resolve_billed_to
    return unless @invoice.billed_to_id.present?

    customer = Customer.find_by(id: @invoice.billed_to_id)
    return unless customer

    @invoice.billed_to_type  = "Customer"
    @invoice.billed_to_name  = customer.name
    @invoice.billed_to_phone = @invoice.billed_to_phone.presence || customer.phone
    @invoice.billed_to_email = @invoice.billed_to_email.presence || customer.email
  end

  def build_booking_items
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
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

  def calculate_totals
    subtotal  = 0
    tax_total = 0

    @invoice.invoice_items.each do |item|
      next if item.marked_for_destruction?

      gross    = item.quantity.to_d * item.unit_price.to_d
      is_room_booking = item.metadata&.dig("type") == "booking"
      tax_rate = is_room_booking ? @invoice.tax_rate.to_d : 0
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

  def link_bookings_to_invoice
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
      next if booking.invoiced?
      
      @invoice.bookings << booking unless @invoice.bookings.include?(booking)
    end
  end

  def mark_bookings_as_invoiced
    return unless params[:booking_ids].present?

    params[:booking_ids].each do |booking_id|
      booking = Booking.find_by(id: booking_id)
      next unless booking
      
      booking.invoiced! unless booking.invoiced?
    end
  end

  # Builds a suggested invoice number to prefill the form. The user can edit or
  # replace it; the value actually saved is whatever they submit (validated for
  # presence and uniqueness on the Invoice model).
  def suggested_invoice_number
    date_part = Time.current.strftime('%Y%m%d')

    last_invoice = Invoice
      .where("invoice_number LIKE ?", "SAR-#{date_part}-%")
      .order(:invoice_number)
      .last

    last_serial =
      if last_invoice.present?
        last_invoice.invoice_number.split('-').last.to_i
      else
        0
      end

    "SAR-#{date_part}-#{format('%05d', last_serial + 1)}"
  end
end