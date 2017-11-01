class UrlShortenerService

  Bitly.use_api_version_3
  Bitly.configure do |config|
    config.api_version = 3
    config.access_token = Rails.application.secrets.bitly["token"]
  end

  class << self
    
    def shorten_link(link)
      begin
        url = Bitly.client.shorten(link)
      rescue StandardError => error
        ExceptionNotifier.notify_exception(error, data: { message: "In shorten_link", env: Rails.env, link: link })
        puts error.inspect
        url = nil
      ensure
        return url.short_url unless url == nil  
        link
      end    
    end
    
  end  
end

