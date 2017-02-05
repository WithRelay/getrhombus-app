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
 
      def to_2dp(amt)
    	 sprintf("%.2f", amt)
      end

      def to_cents(var)
        ((var.to_f.abs)*100).round        # 100 * 1.1
      end 
    end
  end
  
end