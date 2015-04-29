class UrlShortenerService

  class << self
    
    def shorten_link(link)
      begin
        url = Bitly.client.shorten(link)
      rescue StandardError => error
        url = nil
      ensure
        return link if url == nil  
        url
      end    
    end

  end  
end

