# Notification messages shown to users.

class Notification
  include MongoMapper::Document

  timestamps!

  belongs_to :user

  key :event_type, String, :required => true

  # The user who caused the notification.
  belongs_to :origin, :class_name => "User"

  # The entry which provoked the notification.
  key :reason_id
  key :reason_type
  belongs_to :reason, :polymorphic => true

  def unread?
    !self.user.last_read_notifications_at ||
      self.user.last_read_notifications_at < self.created_at
  end

  # Return the question related to this notification, if it exists.
  def question
    case self.event_type
    when "new_answer"
      self.reason.question
    when "new_comment"
      self.reason.find_question
    end
  end
end