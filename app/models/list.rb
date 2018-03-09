class List < ActiveRecord::Base
  
  include SegmentQueries

  belongs_to :user
  serialize :segment, JSON

  has_many :campaign_lists
  has_many :campaign_recipients
  has_many :user_lists, dependent: :destroy
  has_many :campaigns, through: :campaign_lists
  
  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }, unless: lambda { reminder? }

  enum channel: [:sms, :messenger]          # default channel for contacts based list/segments since contacts come from a specific channel
  enum origin: [:merchant, :system]         # list origin specifies whether the list is system generated or created by a merchant (user)
  enum list_type: [:customer, :contact]
  enum campaign_type: [:campaign, :reminder]

  def is_segment?
    self.segment.present?
  end

  # Gets the merchant customers or merchant contacts that belong to a standard list or segment
  def get_mcs(page=1)
    page = page.present? ? page : 1
    class_name = self.customer? ? MerchantCustomer : MerchantContact

    if self.is_segment?
      self.segment['merchant_id'] = self.user_id
      self.segment["time"] = Time.current.beginning_of_day.utc - self.segment['base_val'].to_i.days if self.segment['base_val'].present?
      #class_name.paginate_by_sql(send(self.segment['base_query'], self.segment), page: page, per_page: PAGINATION_PER_PAGE)
      class_name.find_by_sql(send(self.segment['base_query'], self.segment))#, page: page, per_page: PAGINATION_PER_PAGE)
    else
      class_name.joins("inner join user_lists on user_lists.customer_contact_id = #{class_name.table_name}.id")
                .select("#{class_name.table_name}.*").where("user_lists.list_id = #{self.id}")
                .paginate(page: page, per_page: PAGINATION_PER_PAGE)
    end
  end

  def create_default_segments(merchant)
    orn, ct, cus, con = List.origins[:system], List.campaign_types[:campaign], List.list_types[:customer], List.list_types[:contact]
    merchant.lists.create([
      { name: 'New Customers', segment: new_customers_default_segment_data, origin: orn, list_type: cus, campaign_type: ct },
      { name: 'New Contacts', segment: new_contacts_default_segment_data, origin: orn, list_type: con, campaign_type: ct },
      { name: 'Active Customers', segment: active_customers_default_segment_data, origin: orn, list_type: cus, campaign_type: ct },
      { name: 'Active Contacts', segment: active_contacts_default_segment_data, origin: orn, list_type: con, campaign_type: ct },
      { name: 'Inactive Customers', segment: inactive_customers_default_segment_data, origin: orn, list_type: cus, campaign_type: ct },
      { name: 'Inactive Contacts', segment: inactive_contacts_default_segment_data, origin: orn, list_type: con, campaign_type: ct }
    ])
  end

end
