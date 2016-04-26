class TwitterService

  class << self

    def tweet(tweet, token, secret)
      begin
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = Rails.application.secrets.twitter["key"]
          config.consumer_secret     = Rails.application.secrets.twitter["secret"]
          config.access_token        = token
          config.access_token_secret = secret
        end
      
        client.update(tweet)
      rescue StandardError => err 
        nil
      end
    end

  end

end