module SaveRepliesHelper
  def saved_replies_list
    save_replies = current_user.save_replies
    replies_hash = {}
    save_replies.each do |reply|
      replies_hash.store(reply.title, reply.body)
    end
    replies_hash
  end
end
