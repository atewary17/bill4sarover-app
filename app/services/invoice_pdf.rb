class InvoicePdf < Prawn::Document
  def initialize(invoice)
    super(page_size: 'A4', margin: 40)
    @invoice = invoice
    generate
  end

  def generate
    # Header
    header
    
    move_down 20
    
    # Invoice details
    invoice_details
    
    move_down 20
    
    # Items table
    items_table
    
    move_down 10
    
    # Totals
    totals_section
    
    move_down 20
    
    # Notes and terms
    notes_section if @invoice.notes.present? || @invoice.terms_and_conditions.present?
    
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

  def header
    text "INVOICE", size: 24, style: :bold, align: :center
    move_down 5
    text sanitize_text(@invoice.invoice_number), size: 14, align: :center, color: '666666'
    
    move_down 20
    
    # Company info (left) and invoice info (right)
    bounding_box([0, cursor], width: 270) do
      text "Bill4Sarover", size: 12, style: :bold
      text "Hotel Management System", size: 10
      text "Kolkata, West Bengal, IN", size: 10
    end
    
    bounding_box([300, cursor + 60], width: 240) do
      data = [
        ["Invoice #", sanitize_text(@invoice.invoice_number)],
        ["Status", sanitize_text(@invoice.status.humanize)],
        ["Issued", @invoice.issued_at&.strftime("%d %b %Y") || "—"],
        ["Due Date", @invoice.due_date&.strftime("%d %b %Y") || "—"]
      ]
      
      table(data, cell_style: { borders: [], padding: 2 }, column_widths: [80, 160]) do
        column(0).font_style = :bold
      end
    end
  end

  def invoice_details
    move_down 40
    
    text "BILLED TO", size: 10, style: :bold, color: '666666'
    move_down 5
    
    text sanitize_text(@invoice.billed_to_name), size: 12, style: :bold
    text sanitize_text(@invoice.billed_to_phone) if @invoice.billed_to_phone.present?
    text sanitize_text(@invoice.billed_to_email) if @invoice.billed_to_email.present?
    text "GST: #{sanitize_text(@invoice.company_gst_number)}" if @invoice.company_gst_number.present?
  end

  def items_table
    move_down 20
    
    items_data = [["Description", "Qty", "Rate", "Tax", "Amount"]]
    
    @invoice.invoice_items.each do |item|
      items_data << [
        sanitize_text(item.description),
        item.quantity.to_i.to_s,
        "Rs #{format_currency(item.unit_price)}",
        item.tax_amount.to_d > 0 ? "Rs #{format_currency(item.tax_amount)}" : "-",
        "Rs #{format_currency(item.line_total)}"
      ]
    end
    
    table(items_data, header: true, width: bounds.width,
          cell_style: { padding: 8 }) do
      row(0).font_style = :bold
      row(0).background_color = 'eeeeee'
      columns(1..4).align = :right
    end
  end

  def totals_section
    move_down 10
    
    bounding_box([300, cursor], width: 240) do
      totals_data = [
        ["Subtotal", "Rs #{format_currency(@invoice.subtotal)}"]
      ]
      
      if @invoice.discount_amount.to_d > 0
        totals_data << ["Discount", "- Rs #{format_currency(@invoice.discount_amount)}"]
      end
      
      totals_data << ["Taxable Amount", "Rs #{format_currency(@invoice.taxable_amount)}"]
      
      if @invoice.tax_amount.to_d > 0
        totals_data << ["Tax (#{@invoice.tax_rate}%)", "Rs #{format_currency(@invoice.tax_amount)}"]
      end
      
      totals_data << ["", ""]
      totals_data << ["TOTAL", "Rs #{format_currency(@invoice.total_amount)}"]
      
      table(totals_data, cell_style: { borders: [], padding: [2, 5] }, column_widths: [140, 100]) do
        column(0).font_style = :bold
        column(1).align = :right
        row(-1).font_style = :bold
        row(-1).size = 14
        row(-1).border_width = 2
        row(-1).border_color = '000000'
        row(-1).borders = [:top]
      end
    end
  end

  def notes_section
    if @invoice.terms_and_conditions.present?
      move_down 20
      text "Terms & Conditions", size: 10, style: :bold
      move_down 5
      text sanitize_text(@invoice.terms_and_conditions), size: 9
    end
    
    if @invoice.notes.present?
      move_down 15
      text "Notes", size: 10, style: :bold
      move_down 5
      # Show only the last note (after last separator)
      last_note = @invoice.notes.split("-----").last.to_s.strip
      text sanitize_text(last_note), size: 9, color: '666666'
    end
  end

  def footer
    repeat(:all) do
      bounding_box([bounds.left, bounds.bottom + 25], width: bounds.width) do
        stroke_horizontal_rule
        move_down 5
        text "Thank you for your business!", size: 9, align: :center, color: '666666'
      end
    end
  end

  def format_currency(number)
    parts = sprintf("%.2f", number).split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
    parts.join('.')
  end
end