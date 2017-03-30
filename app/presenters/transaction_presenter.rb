class TransactionPresenter < BasePresenter

	def format_txn_amount
    return '-' if @model.amount_with_taxes.blank?
    "$" + Toolbox::Decimal.to_2dp(@model.amount_with_taxes)
  end


  def transaction_user_name
    return @model.user.full_name if @model.user.full_name.present?
    @model.user.email
  end
end
