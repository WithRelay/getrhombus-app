module TransactionsHelper
    def transactions
    today_transactions = Transaction.where(team_id: current_user.id)
      .where("created_at >= ?", Time.current.beginning_of_day).pluck(:amount_with_taxes, :app_fee, :stripe_fee)
    yesterday_transactions = Transaction.where(team_id: current_user.id)
      .where("created_at < ? && created_at >= ?", Time.current.beginning_of_day, (Time.current.beginning_of_day - 1.days))
      .pluck(:amount_with_taxes, :app_fee, :stripe_fee)
    @all_transactions = [today_transactions, yesterday_transactions]
    @all_transactions
  end

  def transactions_change
    transactions   
    tday_txns_count = @all_transactions[0].count
    yday_txns_count = @all_transactions[1].count
    percent_change = (tday_txns_count - yday_txns_count).to_f/yday_txns_count * 100 if yday_txns_count > 0
    display_change( percent_change.round ) if percent_change.present?
  end

  def transactions_total_amount
    @tday_txns_amount = 0
    @all_transactions[0].each{|arr| @tday_txns_amount += arr[0] }
    @tday_txns_amount
  end

  def transactions_total_amount_change
    @yday_txns_amount = 0
    @all_transactions[1].each{|arr| @yday_txns_amount += arr[0] }
    percent_change = (@tday_txns_amount - @yday_txns_amount).to_f/@yday_txns_amount * 100 if @yday_txns_amount > 0
    display_change(percent_change.round) if percent_change.present?
  end

  def transactions_net_sales
    @tday_net_sale = 0
    @all_transactions[0].each{|arr| @tday_net_sale +=   (arr[0] - (arr[1].to_f + arr[2].to_f))}
    @tday_net_sale
  end

  def transactions_net_sales_change
    @yday_net_sale = 0
    @all_transactions[1].each{|arr| @yday_net_sale += (arr[0] - (arr[1].to_f + arr[2].to_f))}
    percent_change = (@tday_net_sale - @yday_net_sale).to_f/@yday_net_sale * 100 if @yday_net_sale > 0
    display_change(percent_change.round) if percent_change.present?
  end

end
