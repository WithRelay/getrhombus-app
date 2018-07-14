class RulesController < ApplicationController
  before_action :set_rule, only: [:destroy]
  def destroy
    rule = Rule.find params[:id]
    rule.destroy
    redirect_to user_rules_path(current_user), flash: { notice: 'Rule was deleted' }
  end

  private

  def set_rule
    @rule = Rule.find params[:id]
  end
end
