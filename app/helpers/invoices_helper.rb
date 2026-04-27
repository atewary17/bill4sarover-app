module InvoicesHelper
  ONES = %w[Zero One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve
            Thirteen Fourteen Fifteen Sixteen Seventeen Eighteen Nineteen].freeze
  TENS = %w[Zero Ten Twenty Thirty Forty Fifty Sixty Seventy Eighty Ninety].freeze

  def number_to_words(number)
    amount = number.to_f
    rupees = amount.floor
    paise  = ((amount - rupees) * 100).round

    result = "Rupees #{convert_to_words(rupees)}"
    result += " and #{convert_to_words(paise)} Paise" if paise > 0
    result
  end

  private

  def convert_to_words(n)
    n = n.to_i
    return ONES[n] if n < 20
    return "#{TENS[n / 10]}#{n % 10 > 0 ? ' ' + ONES[n % 10] : ''}" if n < 100

    if n < 1_000
      "#{ONES[n / 100]} Hundred#{n % 100 > 0 ? ' ' + convert_to_words(n % 100) : ''}"
    elsif n < 1_00_000
      "#{convert_to_words(n / 1_000)} Thousand#{n % 1_000 > 0 ? ' ' + convert_to_words(n % 1_000) : ''}"
    elsif n < 1_00_00_000
      "#{convert_to_words(n / 1_00_000)} Lakh#{n % 1_00_000 > 0 ? ' ' + convert_to_words(n % 1_00_000) : ''}"
    else
      "#{convert_to_words(n / 1_00_00_000)} Crore#{n % 1_00_00_000 > 0 ? ' ' + convert_to_words(n % 1_00_00_000) : ''}"
    end
  end
end
