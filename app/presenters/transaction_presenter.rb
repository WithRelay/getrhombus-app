class TransactionPresenter < BasePresenter

	def format_txn_amount
    return '--' if @model.amount_with_taxes.blank?
    "$" + Toolbox::Decimal.to_int_or_2dp(@model.amount_with_taxes)
  end


  def transaction_user_name
    @model.user.full_name
  end
end
