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
 
    end
  end
  
end