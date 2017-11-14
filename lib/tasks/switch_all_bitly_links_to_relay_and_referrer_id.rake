
# Task 4. Tested. Uncomment code for production deploy.

desc "switch all bitly links to relay and referrer_id"
task :switch_all_bitly_links_to_relay_and_referrer_uid => :environment do

  ActiveRecord::Base.transaction do
    default_url = User.new.url_helpers.new_user_registration_url
    #User.all.each do |user|
    User.where("id >= 1985").each do |user|
      puts "\n #{user.email}"
      url, uid = nil, nil
      
      # Change all bitly links to use uids and use new relay domain
      # Notify the new mexico guy
      
      if user.is_merchant?
        uid = user.relay_uid
        uid = user.generate_uid if uid.blank?
        puts uid
        link = "#{default_url}?referrer_uid=#{uid}"

=begin
 <redacted_email>
t2syuap4
#<BitlyError: RATE_LIMIT_EXCEEDED - '403'>

=end

        # test for one account and uncomment in production
        #url = link + '1'
        url = UrlShortenerService.shorten_link(link)
        puts url
        raise StandardError if !url || url == link
      end

      user.update!(short_url: url, relay_uid: uid)
    end
  end
end