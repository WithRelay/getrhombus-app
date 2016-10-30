
=begin	
 #only merchant should have bitly links
 select * from users where short_url = '' # is not null
 and user_level = 0
=end

desc "switch all bitly links to relay and referrer_id"
task :switch_all_bitly_links_to_relay_and_referrer_id => :environment do

  User.all.each do |u|
    # change all bitly links to use ids
    # and use new relay domain
    # Notify the new mexico guy
    if u.user_level == 1 && u.short_url.present?
      #u.short_url = UrlShortenerService.shorten_link("test.getrhombus.com/signup?referrer_id=#{u.id}")
      #u.short_url = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?referrer_id=#{u.id}")
    else
      u.short_url = nil
    end
    u.save
  end
end