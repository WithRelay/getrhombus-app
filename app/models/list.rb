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


  # Gets the merchant customers or merchant contacts that belong to a standard list or segment
  def get_mcs(page=1)
    page = page.present? ? page : 1
    class_name = self.customer? ? MerchantCustomer : MerchantContact

    if self.segment.present?
      self.segment['merchant_id'] = self.user_id
      self.segment["time"] = Time.current.beginning_of_day.utc - self.segment['base_val'].to_i.days if self.segment['base_val'].present?
      class_name.paginate_by_sql(send(self.segment['base_query'], self.segment), page: page, per_page: PAGINATION_PER_PAGE)
    else
      class_name.joins("inner join user_lists on user_lists.customer_contact_id = #{class_name.table_name}.id")
                .select("#{class_name.table_name}.*").where("user_lists.list_id = #{self.id}")
                .paginate(page: page, per_page: PAGINATION_PER_PAGE)
    end

    #[MerchantCustomer.find(32)]
  end
end
