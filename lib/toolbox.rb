module Toolbox

  module StringGen
    class << self

      def generate_random_string(length)
        SecureRandom.random_number(36**length).to_s(36).rjust(length, "0")
      end

    end
  end

  module Decimal
    class << self

      def to_int_or_2dp(amt)
    	  amt = sprintf("%.2f", amt)
        amt.split(".").first if amt.include? ".00"
      end

      def to_cents(var)
        ((var.to_f.abs)*100).round        # 100 * 1.1
      end

      def cents_to_int_or_2dp(var)
        var = "%g" % (var.to_f / 100.00)
        (var.include? ".") ? to_int_or_2dp(var) : var
      end

    end
  end
end
