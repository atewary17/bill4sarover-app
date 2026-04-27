class InvoicePdf < Prawn::Document
  # Update these to match your hotel's details
  HOTEL = {
    name:    ENV.fetch('HOTEL_NAME',    'Sarover Hotel'),
    tagline: ENV.fetch('HOTEL_TAGLINE', ''),
    address: ENV.fetch('HOTEL_ADDRESS', 'Kolkata, West Bengal, India'),
    phone:   ENV.fetch('HOTEL_PHONE',   ''),
    gst:     ENV.fetch('HOTEL_GST',     '')
  }.freeze

  def initialize(invoice)
    super(page_size: 'A4', margin: [30, 35, 50, 35])
    @invoice = invoice
    @booking_items    = invoice.invoice_items.select { |i| i.metadata&.dig('type') == 'booking' }
    @service_items    = invoice.invoice_items.select { |i| i.metadata&.dig('type') == 'service_charge' }
    @adhoc_items      = invoice.invoice_items.select { |i| i.metadata&.dig('type') == 'adhoc' }
    @room_subtotal    = @booking_items.sum { |i| i.gross_amount.to_d }
    @service_subtotal = @service_items.sum { |i| i.gross_amount.to_d }
    @adhoc_subtotal   = @adhoc_items.sum   { |i| i.gross_amount.to_d }
    @total_gst        = @booking_items.sum { |i| i.tax_amount.to_d }
    @total_paid       = invoice.payments.sum(:amount).to_d
    @balance_due      = invoice.total_amount.to_d - @total_paid
    generate
  end

  def generate
    hotel_header
    move_down 6
    details_grid
    move_down 6
    line_items_table
    move_down 6
    tax_summary_and_totals
    move_down 8
    amount_in_words_section
    move_down 8
    signatures_section
    page_footer
  end

  private

  # Safe text encoder – strips characters Windows-1252 can't handle
  def s(text)
    return '' if text.nil?
    text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
  rescue
    text.to_s.gsub(/[^\x00-\x7F]/, '')
  end

  def fc(number)
    parts = sprintf('%.2f', number.to_d).split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
    parts.join('.')
  end

  # ── 1. Hotel Header ──────────────────────────────────────────────────
  def hotel_header
    text s(HOTEL[:name]), size: 14, style: :bold, align: :center
    text s(HOTEL[:tagline]), size: 9, align: :center unless HOTEL[:tagline].to_s.strip.empty?
    text s(HOTEL[:address]), size: 9, align: :center
    text "Phone : #{s(HOTEL[:phone])}", size: 9, align: :center unless HOTEL[:phone].to_s.strip.empty?
    move_down 5
    stroke_horizontal_rule
    move_down 4

    w = bounds.width
    third = w / 3.0

    # Row: GST (left) | TAX INVOICE (center) | ORIGINAL FOR RECIPIENT (right)
    float { bounding_box([0, cursor], width: third) do
      text s(HOTEL[:gst].to_s.strip.empty? ? '' : "GST # #{HOTEL[:gst]}"), size: 8
      text s(@invoice.company_gst_number.present? ? "Cust. GST: #{@invoice.company_gst_number}" : ''), size: 8
    end }
    float { bounding_box([third, cursor], width: third) do
      text 'TAX INVOICE', size: 11, style: :bold, align: :center
    end }
    bounding_box([third * 2, cursor], width: third) do
      text 'ORIGINAL FOR RECIPIENT', size: 8, align: :right
    end

    move_down 4
    stroke_horizontal_rule
  end

  # ── 2. Two-Column Details Grid ───────────────────────────────────────
  def details_grid
    move_down 5
    booking = @invoice.bookings.first
    w       = bounds.width
    col_w   = w / 2.0 - 6

    left_rows = [
      ['Room No.', room_label(booking)],
      ['Invoice No.', s(@invoice.invoice_number)],
      ['Guest Name', s(@invoice.billed_to_name)],
    ]
    left_rows << ['Phone', s(@invoice.billed_to_phone)] if @invoice.billed_to_phone.present?
    left_rows << ['Email', s(@invoice.billed_to_email)] if @invoice.billed_to_email.present?
    left_rows << ['GST #', s(@invoice.company_gst_number)] if @invoice.company_gst_number.present?

    right_rows = [
      ['Date',   @invoice.created_at.strftime('%d-%b-%Y')],
      ['Status', s(@invoice.status.upcase)],
    ]
    if booking
      right_rows += [
        ['Check In',      booking.check_in.strftime('%d-%b-%y  %H:%M')],
        ['Check Out',     booking.check_out.strftime('%d-%b-%y  %H:%M')],
        ['No. of Day(s)', ((booking.check_out - booking.check_in) / 1.day).to_i.to_s],
      ]
    end
    right_rows << ['Due Date', @invoice.due_date&.strftime('%d-%b-%Y') || '—']

    label_w = 80
    y = cursor

    bounding_box([0, y], width: col_w) do
      table(left_rows,
            cell_style: { borders: [], padding: [2, 3], size: 9 },
            column_widths: [label_w, col_w - label_w]) do
        column(0).font_style = :bold
      end
    end

    bounding_box([col_w + 12, y], width: col_w) do
      table(right_rows,
            cell_style: { borders: [], padding: [2, 3], size: 9 },
            column_widths: [label_w, col_w - label_w]) do
        column(0).font_style = :bold
      end
    end

    move_down 5
    stroke_horizontal_rule
  end

  # ── 3. Line Items Table ──────────────────────────────────────────────
  def line_items_table
    move_down 5
    w = bounds.width

    # Column widths (must sum to w ≈ 525)
    cw = { date: 58, desc: 0, hsn: 52, qty: 42, rate: 58, charge: 62, credit: 42 }
    cw[:desc] = w - cw.values.sum
    col_widths = cw.values

    header = [['Date', 'Description', 'HSN/SAC', 'Days/Qty', 'Rate', 'Charge', 'Credit']]
    rows   = build_item_rows

    # Pad to at least 7 data rows for a clean look
    padding = [7 - rows.count, 0].max
    padding.times { rows << ['', '', '', '', '', '', ''] }

    all_rows = header + rows

    table(all_rows, header: true, width: w, column_widths: col_widths,
          cell_style: { padding: [3, 5], size: 9, border_color: 'BBBBBB' }) do
      # Header row
      row(0).font_style      = :bold
      row(0).background_color = '2C3E50'
      row(0).text_color       = 'FFFFFF'

      # Right-align numeric columns
      columns(2..6).align = :right

      # Section header rows (colspan rows are identified by being a Hash array)
      (1..row_length - 1).each do |r|
        next unless cells[r, 0].content.to_s =~ /^(SERVICE CHARGES|ADDITIONAL ITEMS)$/
        row(r).background_color = cells[r, 0].content.start_with?('SERVICE') ? 'FFF8E1' : 'F3F0FF'
        row(r).font_style = :bold
        row(r).size = 8
      end
    end
  end

  def build_item_rows
    rows = []

    @booking_items.each do |item|
      ci     = parse_time(item.metadata&.dig('check_in'))
      co     = parse_time(item.metadata&.dig('check_out'))
      room   = s(item.metadata&.dig('room_number').to_s)
      rtype  = s(item.metadata&.dig('room_type').to_s)
      nights = item.quantity.to_i
      rate   = item.unit_price.to_d

      if ci && nights > 0
        nights.times do |n|
          rows << [
            (ci + n.days).strftime('%d-%b-%y'),
            "#{room} #{rtype} Room Tariff",
            '996311', '1', fc(rate), fc(rate), '0.00'
          ]
        end
      else
        rows << [
          item.created_at.strftime('%d-%b-%y'),
          s(item.description),
          '996311', item.quantity.to_i.to_s,
          fc(item.unit_price), fc(item.gross_amount), '0.00'
        ]
      end
    end

    unless @service_items.empty?
      rows << ['SERVICE CHARGES', '', '', '', '', '', '']
      @service_items.each do |item|
        rows << [
          item.created_at.strftime('%d-%b-%y'), s(item.description),
          '—', item.quantity.to_i.to_s,
          fc(item.unit_price), fc(item.gross_amount), '0.00'
        ]
      end
    end

    unless @adhoc_items.empty?
      rows << ['ADDITIONAL ITEMS', '', '', '', '', '', '']
      @adhoc_items.each do |item|
        rows << [
          item.created_at.strftime('%d-%b-%y'), s(item.description),
          '—', item.quantity.to_i.to_s,
          fc(item.unit_price), fc(item.gross_amount), '0.00'
        ]
      end
    end

    rows
  end

  # ── 4. Two-Column Tax Summary + Totals ──────────────────────────────
  def tax_summary_and_totals
    stroke_horizontal_rule
    move_down 6

    w       = bounds.width
    left_w  = (w * 0.44).floor
    right_w = w - left_w - 10
    y       = cursor

    # Left: SGST / CGST summary
    bounding_box([0, y], width: left_w) do
      half_rate = (@invoice.tax_rate.to_d / 2).round(1)
      tax_rows = [
        [{ content: 'Tax Summary (Room Charges Only)', colspan: 4,
           font_style: :bold, size: 8, background_color: 'EEF2F7' }],
        ['SGST%', 'CGST%', 'Amount', 'Tax Amt.'],
        ["#{half_rate}%", "#{half_rate}%", fc(@room_subtotal), fc(@total_gst)]
      ]
      qw = left_w / 4.0
      table(tax_rows, width: left_w,
            cell_style: { padding: [3, 5], size: 9, border_color: 'BBBBBB' },
            column_widths: [qw, qw, qw, qw]) do
        row(1).font_style = :bold
        row(1).background_color = 'F8F9FA'
        columns(1..3).align = :right
      end
    end

    # Right: calculation breakdown
    bounding_box([left_w + 10, y], width: right_w) do
      half_rate = (@invoice.tax_rate.to_d / 2).round(1)
      lw = (right_w * 0.58).floor
      rw = right_w - lw

      breakdown = [
        ['Gross Amount', fc(@room_subtotal + @service_subtotal + @adhoc_subtotal)],
      ]
      if @total_gst > 0
        breakdown << ["Add SGST #{half_rate}%", fc(@total_gst / 2)]
        breakdown << ["Add CGST #{half_rate}%", fc(@total_gst / 2)]
      end
      breakdown << ['Invoice Amount', fc(@invoice.total_amount)]
      breakdown << ['Less Advance',   fc(@total_paid)]
      breakdown << ['Balance',        fc(@balance_due)]

      invoice_row  = breakdown.index { |r| r[0] == 'Invoice Amount' }
      balance_row  = breakdown.index { |r| r[0] == 'Balance' }

      table(breakdown, width: right_w,
            cell_style: { padding: [3, 6], size: 9, border_color: 'BBBBBB' },
            column_widths: [lw, rw]) do
        column(1).align = :right
        row(invoice_row).font_style = :bold
        row(invoice_row).background_color = 'EEF2F7'
        row(balance_row).font_style = :bold
        row(balance_row).background_color = 'EEF2F7'
      end
    end
  end

  # ── 5. Amount in Words ───────────────────────────────────────────────
  def amount_in_words_section
    stroke_horizontal_rule
    move_down 4
    text "Amount in Words : #{words_for(@invoice.total_amount)} Only", size: 9, style: :italic
    move_down 4
    stroke_horizontal_rule
  end

  # ── 6. Agreement + Signatures ────────────────────────────────────────
  def signatures_section
    move_down 8
    text 'I AGREE THAT I AM RESPONSIBLE FOR THE FULL PAYMENT OF THIS INVOICE, IN THE', size: 8
    text 'EVENT IT IS NOT PAID BY THE COMPANY, ORGANISATION OR PERSON INDICATED ABOVE.', size: 8
    move_down 24
    w  = bounds.width
    cw = w / 3.0
    y  = cursor

    [['CASHIER / FO SIGNATURE', 0], ['GUEST SIGNATURE', cw * 2]].each do |label, x|
      bounding_box([x, y], width: cw) do
        stroke_horizontal_rule
        move_down 3
        text label, size: 8, align: :center
      end
    end

    move_down 16
    stroke_horizontal_rule
    move_down 5
    text 'Thank you for staying with us.', size: 10, style: :italic, align: :center
  end

  # ── 7. Repeating page footer ─────────────────────────────────────────
  def page_footer
    repeat(:all) do
      bounding_box([bounds.left, bounds.bottom + 18], width: bounds.width) do
        text "#{s(HOTEL[:name])}  |  Invoice #{s(@invoice.invoice_number)}",
             size: 7, align: :center, color: 'AAAAAA'
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────────
  def room_label(booking)
    return '—' unless booking&.room
    "#{booking.room.room_number} (#{booking.room.room_type&.upcase})"
  end

  def parse_time(value)
    return nil if value.blank?
    Time.parse(value.to_s)
  rescue
    nil
  end

  def words_for(number)
    ones = %w[Zero One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve
              Thirteen Fourteen Fifteen Sixteen Seventeen Eighteen Nineteen]
    tens = %w[Zero Ten Twenty Thirty Forty Fifty Sixty Seventy Eighty Ninety]

    convert = lambda do |n|
      n = n.to_i
      next ones[n]                                                              if n < 20
      next "#{tens[n / 10]}#{n % 10 > 0 ? ' ' + ones[n % 10] : ''}"           if n < 100
      if    n < 1_000
        "#{ones[n / 100]} Hundred#{n % 100 > 0 ? ' ' + convert.(n % 100) : ''}"
      elsif n < 1_00_000
        "#{convert.(n / 1_000)} Thousand#{n % 1_000 > 0 ? ' ' + convert.(n % 1_000) : ''}"
      elsif n < 1_00_00_000
        "#{convert.(n / 1_00_000)} Lakh#{n % 1_00_000 > 0 ? ' ' + convert.(n % 1_00_000) : ''}"
      else
        "#{convert.(n / 1_00_00_000)} Crore#{n % 1_00_00_000 > 0 ? ' ' + convert.(n % 1_00_00_000) : ''}"
      end
    end

    amount = number.to_f
    rupees = amount.floor
    paise  = ((amount - rupees) * 100).round
    result = "Rupees #{convert.(rupees)}"
    result += " and #{convert.(paise)} Paise" if paise > 0
    result
  end
end
