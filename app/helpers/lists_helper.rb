module ListsHelper
  def user_list_id(list)
    list.user_lists.collect { |user_list| user_list.user.id}.join(',')
  end
end
