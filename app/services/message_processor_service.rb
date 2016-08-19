class MessageProcessor

    def initialize(message)
        @message = message
        puts "initialize: #{@message}"
    end

    

    def process_message
    	puts "process message: #{@message}"
        # This gets invoked whenever a message is received
    end



end