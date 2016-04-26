class UrlShortenerService

  Bitly.use_api_version_3
  Bitly.configure do |config|
    config.api_version = Rails.application.secrets.bitly["token"]
    config.access_token = Rails.application.secrets.bitly["token"]
  end

  class << self
    
    def shorten_link(link)
      begin
        url = Bitly.client.shorten(link)
      rescue StandardError => error
        url = nil
      ensure
        return url.short_url unless url == nil  
        link
      end    
    end

  end  
end

