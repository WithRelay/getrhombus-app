class UrlShortenerService

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

