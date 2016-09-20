class ModifyPlansSubscriptionsHashtagsCoupons < ActiveRecord::Migration
  def change
    change_column :subscriptions, :team_id, :integer, after: :user_id

    add_column :coupons, :user_id, :integer, after: :id
    add_column :coupons, :stripe_coupon_id, :integer, after: :user_id
    add_index :coupons, :user_id
    add_foreign_key :coupons, :users

    change_column :hashtags, :enable_tweet, :boolean, after: :user_id
    change_column :hashtags, :tag_type, :integer, after: :user_id
    change_column :hashtags, :interval, :string, after: :user_id
    change_column :hashtags, :interval_count, :integer, after: :user_id

    rename_column :plans, :owner, :user_id
    add_index :plans, :user_id
    add_foreign_key :plans, :users
  end
end
