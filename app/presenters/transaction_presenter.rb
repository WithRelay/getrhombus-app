class TransactionPresenter < BasePresenter

	def format_txn_amount
    return '-' if @model.amount_with_taxes.blank?
    "$" + Toolbox::Decimal.to_2dp(@model.amount_with_taxes)
  end
end
