module Toolbox
    
  module StringGen
    class << self
      
      def generate_random_string(length)
        SecureRandom.random_number(36**length).to_s(36).rjust(length, "0") 
      end

    end
  end
  
end