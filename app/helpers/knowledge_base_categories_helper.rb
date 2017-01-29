module KnowledgeBaseCategoriesHelper

  def date_in_words(date)
    if date >= 0.days.ago.beginning_of_day
      'Today'
    else
      time_ago_in_words(date) + ' ago'
    end
  end

  def breadcrumb_item
    request.url.split('/').last.gsub('-', ' ').titleize
  end
end
