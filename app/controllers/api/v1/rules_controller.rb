class Api::V1::RulesController < Api::V1::BaseController
  def create
    rule = current_user.rules.new(rule_params)
    if rule.save
      render json: { notice: 'Rule has been created' }
    else
      render json:{ error: rule.errors.messages , data: rule , status: 500 }
    end
  end

  private

  def rule_params
    params.require(:rule).permit(:text, :rule_type, :message_length, :response)
  end
end
