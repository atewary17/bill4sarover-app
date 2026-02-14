class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show]

  def index
    @invoices = Invoice.order(created_at: :desc)
  end

  def new
    @invoice = Invoice.new
    @invoice.invoice_items.build
    @bookings = Booking.where(id: params[:booking_ids])
    @customers = @bookings.map(&:customer).uniq
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.invoice_number = generate_invoice_number
    @invoice.status = "draft"

    build_booking_items
    calculate_totals

    if @invoice.save
      redirect_to @invoice, notice: "Invoice created successfully"
    else
      @bookings = Booking.where(status: ["checked_out", "cancelled"])
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:invoice_items).find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
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
      :terms_and_conditions,
      invoice_items_attributes: [
        :description,
        :quantity,
        :unit_price,
        :line_discount_type,
        :line_discount_value,
        :tax_rate,
        :source_type,
        :source_id,
        :metadata
      ]
    )
  end

  def build_booking_items
    return unless params[:booking_ids]

    params[:booking_ids].each do |booking_id|
      booking = Booking.find(booking_id)
      nights = ((booking.check_out - booking.check_in) / 1.day).to_i

      @invoice.invoice_items.build(
        description: "Room #{booking.room&.room_number}",
        quantity: nights,
        unit_price: booking.room&.price || 0,
        source: booking,
        metadata: {
          check_in: booking.check_in,
          check_out: booking.check_out
        }
      )
    end
  end

  def calculate_totals
    subtotal = 0
    tax_total = 0

    @invoice.invoice_items.each do |item|
      gross = item.quantity.to_d * item.unit_price.to_d

      discount =
        if item.line_discount_type == "percentage"
          gross * item.line_discount_value.to_d / 100
        else
          item.line_discount_value.to_d
        end

      taxable = gross - discount
      tax = taxable * (@invoice.tax_rate.to_d / 100)

      item.gross_amount = gross
      item.line_discount_amount = discount
      item.tax_amount = tax
      item.line_total = taxable + tax

      subtotal += taxable
      tax_total += tax
    end

    invoice_discount =
      if @invoice.discount_type == "percentage"
        subtotal * @invoice.discount_value.to_d / 100
      else
        @invoice.discount_value.to_d
      end

    @invoice.subtotal = subtotal
    @invoice.discount_amount = invoice_discount
    @invoice.taxable_amount = subtotal - invoice_discount
    @invoice.tax_amount = tax_total
    @invoice.total_amount = @invoice.taxable_amount + tax_total
  end

  def generate_invoice_number
    "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end
