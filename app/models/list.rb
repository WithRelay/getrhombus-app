class List < ActiveRecord::Base
  include SegmentQueries

  belongs_to :user
  serialize :segment, JSON
  has_many :user_lists
  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }
  has_many :campaigns, through: :campaign_lists
  has_many :campaign_lists
  has_many :campaign_recipients

  # default channel for contacts based list/segments since contacts come from a specific channel
  enum channel: [:sms, :messenger]
  enum list_type: [:customer, :contact]
  # List origin specifies whether the list is system generated or created by a merchant (user)
  enum origin: [:merchant, :system]

  # Gets the merchant customers or merchant contacts that belong to a standard list or segment
  def get_mcs(page=1)
    class_name = self.customer? ? MerchantCustomer : MerchantContact

    if self.segment.present?
      self.segment['merchant_id'] = self.user_id
      self.segment["time"] = Time.current.beginning_of_day - self.segment['days'].days if self.segment['days'].present?
      class_name.paginate_by_sql(send(self.segment['base_query'], self.segment), page: page, per_page: PAGINATION_PER_PAGE)
    else
      class_name.joins("inner join user_lists on user_lists.customer_contact_id = #{class_name.table_name}.id")      
                .select("#{class_name.table_name}.*").where("user_lists.list_id = #{self.id}")
                .paginate(page: page, per_page: PAGINATION_PER_PAGE)      
    end
  end
end
