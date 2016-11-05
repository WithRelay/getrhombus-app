class CouponPresenter < BasePresenter

  def format_time
    @model.redeem_by.present? ? Time.zone.at(@model.redeem_by).strftime("%d/%m/%Y %I:%M %p") : ''
  end
end
