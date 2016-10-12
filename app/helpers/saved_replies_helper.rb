module SavedRepliesHelper
def saved_replies_list
    saved_replies = current_user.saved_replies
    replies_hash = {}
    saved_replies.each do |reply|
      replies_hash.store(reply.title, reply.body)
    end
    replies_hash
  end
end
