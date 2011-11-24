# -*- coding: utf-8 -*-
class Invitation
  include MongoMapper::Document
  include Support::TokenConfirmable

  @@token_confirmable_key = :invitation_token

  key :_id, String
  key :sender_id, String, :required => true, :index => true
  belongs_to :sender, :class_name => 'User'
  key :recipient_id, String
  belongs_to :recipient, :class_name => 'User'
  key :recipient_email, String
  key :message, String
  key :accepted_at, Time
  key :invitation_token, String, :index => true
  key :sent_at, Time
  key :group_id, String
  key :account_type, String
  belongs_to :group

  key :topic_ids, Array
  has_many :topics, :in => :topic_ids

  token_confirmable_key :invitation_token

  after_create :send_invitation
  after_create :mark_student_as_invited

  validate_on_create :recipient_is_not_user

  validates_format_of :recipient_email, :with => Devise::email_regexp

  ensure_index([[:created_at, -1]])

  timestamps!

  # Send confirmation instructions by email
  def send_invitation
    generate_invitation_token! if self.invitation_token.nil?
    Inviter.delay.invitation(self)
  end

  # Invite a list of emails, trying to link invitations to the user's
  # contacts.
  def self.invite_emails!(sender, group, message, emails)
    invited_count = 0
    faulty_emails = []

    emails.present? && emails.each do |email|
      invitation =
        sender.invitations.first(:recipient_email => email) ||
        Invitation.new(:sender_id => sender.id,
                       :account_type => sender.admin? ? I18n.t("users.account_type.financial_advisor") : nil,
                       :group_id => group.id,
                       :message => message,
                       :recipient_email => email)

      saved = false
      if invitation.new?
        if (saved = invitation.save)
          invited_count += 1
        elsif invitation.errors[:recipient_email].present?
          faulty_emails << email
        end
      end

      if !invitation.new? && !saved
        if sender.admin? 
          invitation.account_type = I18n.t("users.account_type.financial_advisor")
          invitation.save!
        end
        invitation.send_invitation
      end

      if (!invitation.new? || saved) &&
          (contact = sender.contacts.first(:email => email))
        contact.invitation = invitation
        contact.save!
      end

    end

    [invited_count, faulty_emails]
  end

  # Try to find a student with this affiliation's email address and
  # mark it as having been invited.
  def mark_student_as_invited
    if student = Student.find_by_email(self.recipient_email)
      student.has_been_invited = true
      student.save!
    end
  end
  handle_asynchronously :mark_student_as_invited

  private
  def recipient_is_not_user
    user = User.find_by_email(self.recipient_email)
    if user
      unless ( user.account_type == I18n.t("users.account_type.personal") &&
               self.account_type == I18n.t("users.account_type.financial_advisor") )
        self.errors.add(:email, "already registered in StockCrunch!")
      end
    end
  end

end
