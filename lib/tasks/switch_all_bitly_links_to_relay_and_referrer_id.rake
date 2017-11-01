
# Task 4

=begin
desc "switch all bitly links to relay and referrer_id"
task :switch_all_bitly_links_to_relay_and_referrer_uid => :environment do

  ActiveRecord::Base.transaction do
    User.all.each do |user|
      puts user.email
      # Change all bitly links to use uids and use new relay domain
      # Notify the new mexico guy
      if user.is_merchant?
        uid = user.relay_uid || user.generate uid
        puts uid
        user.relay_uid = uid
        link = "#{user.url_helpers.new_user_registration_url}?referrer_uid=#{uid}"
        # test for one account and uncomment in production
        #url = UrlShortenerService.shorten_link(link)
        puts url
        raise StandardError if !url || url == link
      else
        url = nil
      end

      user.short_url = url
      user.save
    end
  end
end
=end