
# Task 4. Tested. Uncomment code for production deploy.

desc "switch all bitly links to relay and referrer_id"
task :switch_all_bitly_links_to_relay_and_referrer_uid => :environment do

  ActiveRecord::Base.transaction do
    default_url = User.new.url_helpers.new_user_registration_url  
    count = 0

    User.where(id: [1..622]).each do |user| #User.where("id >= 1985").each do |user|
      
      puts "\n #{user.email}"
      url, uid = nil, nil
      
      # Change all bitly links to use uids and use new relay domain
      # Notify the new mexico guy
      
      if user.is_merchant?
        count = count + 1

        user.relay_uid = user.generate_uid if user.relay_uid.blank?
        puts user.relay_uid
        link = "#{default_url}?referrer_uid=#{uid}"

        #puts user.errors.inspect
        #return
        # test for one account and uncomment in production
        #url = link + '1'
        #puts link
        user.short_url = UrlShortenerService.shorten_link(link)
        puts user.short_url
        raise StandardError if !url || url == link
      else
        user.relay_uid = nil
        user.short_url = nil
      end

      user.save!(validate: false)

      #if count == 99
       # count = 0
       # sleep 70
      #end
    end


  end
end