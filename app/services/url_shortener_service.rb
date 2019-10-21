class UrlShortenerService

#=begin
  Bitly.use_api_version_3
  Bitly.configure do |config|
    config.api_version = 3
    config.access_token = Rails.application.secrets.bitly["token"]
  end
#=end

  SHORTENER_URL = "url.relay.ng".freeze

  class << self

#=begin
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
#=end

=begin
    def shorten_link(link)
      begin
        values = { domain: SHORTENER_URL, originalURL: link }
        headers = { 'content_type' => 'application/json', 'authorization' => Rails.application.secrets.shortcm["token"] }

        res = HTTParty.post("https://api.short.cm/links", body: values, headers: headers)
        res.code == 200 ? link = res.parsed_response['shortURL'] : (raise StandardError.new("short.cm returned #{res.code}"))
      rescue StandardError => error
        ExceptionNotifier.notify_exception(error, data: { message: "In shorten_link", env: Rails.env, link: link })
      ensure
        link
      end
    end
=end
  end
end

