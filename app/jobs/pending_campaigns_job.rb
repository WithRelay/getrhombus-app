class PendingCampaignsJob

  @queue = Rails.env + "_pending_campaigns"
  
  def self.perform
    ActiveRecord::Base.clear_active_connections!
    begin
      # recurring 
        # 1. next_send_at >= now and < tomorrow (excludes recurring from earlier today or in future dates)

      # one time with date
        # 1. datetime is not null (excludes one time and send immediately) 
        # 2. created_at != date_time (excludes one time and send later today - since that would have been scheduled once campaign was created)
        # 3. and date_time >= now and < tomorrow (excludes one time from earlier today or in future dates)
        
      now = Time.now.utc.to_s(:db)
      # +15 minutes since all campaigns are on the hour and job run 15 mins to the hour
      tomorrow = (Time.now.tomorrow.beginning_of_day.utc + 15.minutes).to_s(:db) 

      # date typecast can be improved
      campaigns = Campaign.active
                        .where("(frequency_type = ? and next_send_at is not null and next_send_at >= ?) OR 
                                (frequency_type = ? and deliver_now = false and date_time is not null and date(date_time) > date(created_at) 
                                  and date_time >= ?)",                                 
                                Campaign.frequency_types['recurring'], now,
                                Campaign.frequency_types['one_time'], now)
                          #.where("(frequency_type = ? and next_send_at is not null and next_send_at >= ? and next_send_at < ?) OR 
                           #       (frequency_type = ? and deliver_now = false and date_time is not null and date(date_time) > date(created_at) 
                            #        and date_time >= ? and date_time < ?)",                                 
                             #     Campaign.frequency_types['recurring'], now, tomorrow,
                              #    Campaign.frequency_types['one_time'], now, tomorrow)

      puts campaigns.inspect
      puts '----'
      #return                  
      campaigns.each do |campaign|      
        if Resque.find_delayed_selection(PendingCampaignsHandlerJob) { |s| s.include?(campaign.id) }.blank?
          campaign_time_utc = campaign.recurring? ? campaign.next_send_at.utc : campaign.date_time.utc        
          Resque.enqueue_at_with_queue(campaign.pending_queue, campaign_time_utc, PendingCampaignsHandlerJob, campaign.id) 
        end
      end
    rescue StandardError => e
      puts e.inspect
      # email team
    end
  end 

end
