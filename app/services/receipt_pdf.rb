class ReceiptPdf < Prawn::Document
  def initialize(invoice, payment)
    super(page_size: 'A4', margin: 40)
    @invoice = invoice
    @payment = payment
    generate
  end

  def generate
    # Header
    text "PAYMENT RECEIPT", size: 20, style: :bold, align: :center
    move_down 5
    text sanitize_text(@payment.receipt_number), size: 12, align: :center, color: '666666'
    
    move_down 30
    
    # Receipt details
    receipt_details
    
    move_down 20
    
    # Payment info
    payment_info
    
    move_down 30
    
    # Invoice summary
    invoice_summary
    
    move_down 30
    
    # Payment note
    if @payment.payment_note.present?
      text "Payment Note:", size: 10, style: :bold
      move_down 5
      text sanitize_text(@payment.payment_note), size: 9
    end
    
    # Footer
    footer
  end

  private

  def sanitize_text(text)
    return "" if text.nil?
    # Convert to string and encode to Windows-1252, replacing incompatible chars
    text.to_s.encode('Windows-1252', 
                     invalid: :replace, 
                     undef: :replace, 
                     replace: '?')
  rescue Encoding::UndefinedConversionError
    # If encoding fails, just remove non-ASCII characters
    text.to_s.gsub(/[^[:print:]\n\r\t]/, '')
  end

  def receipt_details
    data = [
      ["Receipt #", sanitize_text(@payment.receipt_number)],
      ["Date", @payment.paid_at.strftime("%d %b %Y, %H:%M")],
      ["Payment Method", sanitize_text(@payment.payment_method.humanize)],
      ["Reference #", sanitize_text(@payment.reference_number.presence || "-")]
    ]
    
    table(data, cell_style: { borders: [], padding: 3 }, column_widths: [120, 300]) do
      column(0).font_style = :bold
    end
  end

  def payment_info
    move_down 10
    
    bounding_box([0, cursor], width: bounds.width) do
      stroke_bounds
      pad(15) do
        text "AMOUNT PAID", size: 10, color: '666666'
        move_down 5
        text "Rs #{format_currency(@payment.amount)}", 
             size: 24, style: :bold, color: '27ae60'
      end
    end
  end

  def invoice_summary
    text "Invoice Summary", size: 12, style: :bold
    move_down 10
    
    total_paid = @invoice.total_paid
    balance = @invoice.balance_due
    
    data = [
      ["Invoice #", sanitize_text(@invoice.invoice_number)],
      ["Invoice Total", "Rs #{format_currency(@invoice.total_amount)}"],
      ["Total Paid", "Rs #{format_currency(total_paid)}"],
      ["Balance Due", "Rs #{format_currency(balance)}"]
    ]
    
    table(data, cell_style: { borders: [], padding: 3 }, column_widths: [120, 300]) do
      column(0).font_style = :bold
      row(-1).font_style = :bold
      row(-1).size = 12
    end
    
    move_down 10
    
    if balance <= 0
      text "PAID IN FULL", size: 12, style: :bold, color: '27ae60', align: :center
    else
      text "PARTIAL PAYMENT", size: 12, style: :bold, color: 'f39c12', align: :center
    end
  end

  def footer
    repeat(:all) do
      bounding_box([bounds.left, bounds.bottom + 25], width: bounds.width) do
        stroke_horizontal_rule
        move_down 5
        text "This is a computer-generated receipt", size: 8, align: :center, color: '999999'
      end
    end
  end

  def format_currency(number)
    parts = sprintf("%.2f", number).split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
    parts.join('.')
  end
end