class Answer < Comment
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include Support::Versionable

  key :_id, String

  key :body, String, :required => true
  key :language, String, :default => 'en'
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false
  key :wiki, Boolean, :default => false

  timestamps!

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :question_id, String
  belongs_to :question

  key :content_image_ids, Array
  has_many :content_images, :in => :content_image_ids

  has_many :flags, :as => "flaggeable", :dependent => :destroy

  has_many :comments, :foreign_key => "commentable_id", :class_name => "Comment", :order => "created_at asc", :dependent => :destroy
  has_many :notifications, :as => "reason", :dependent => :destroy

  # This ought to be has_one, but it wasn't working
  has_many :news_updates, :as => "entry", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id

  validates_uniqueness_of :user_id, :scope => :question_id

  versionable_keys :body
  filterable_keys :body

  validate :disallow_spam
  validate :check_unique_answer, :if => lambda { |a| (!a.group.forum && !a.disable_limits?) }

  after_create :create_news_update, :new_answer_notification,
    :increment_user_topic_answers_count
  before_destroy :unhide_news_update, :decrement_user_topic_answers_count

  ensure_index([[:user_id, 1], [:question_id, 1]])

  def title
    self.question.title
  end

  def topic_ids
    self.question.topic_ids
  end

  def topics
    self.question.topics
  end

  def check_unique_answer
    check_answer = Answer.first(:question_id => self.question_id,
                               :user_id => self.user_id)

    if !check_answer.nil? && check_answer.id != self.id
      self.errors.add(:limitation, "Your can only post one answer per question.")
      return false
    end
  end

  def update_question_answered_with
    # Update question 'answered' status
    if !self.question.answered && self.votes_average >= 1
      Question.set(self.question.id, {:answered_with_id => self.id})
    elsif self.question.answered_with_id == self.id && self.votes_average < 1
      other_good_answer = self.question.answers.detect { |answer|
        answer.votes_average >= 1
      }

      answered_with_id = other_good_answer ? other_good_answer.id : nil

      Question.set(self.question.id, {:answered_with_id => answered_with_id})
    end
  end

  def on_add_vote(v, voter)
    if v > 0
      self.user.update_reputation(:answer_receives_up_vote, self.group)
      voter.on_activity(:vote_up_answer, self.group)
      self.question.on_answer_votes_balance_up self
    else
      self.user.update_reputation(:answer_receives_down_vote, self.group)
      voter.on_activity(:vote_down_answer, self.group)
      self.question.on_answer_votes_balance_down self
    end

    UserTopicInfo.vote_added!(self, v)
    update_question_answered_with
  end

  def on_remove_vote(v, voter)
    if v > 0
      self.user.update_reputation(:answer_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_answer, self.group) if voter
      self.question.on_answer_votes_balance_down self
    else
      self.user.update_reputation(:answer_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_answer, self.group) if voter
      self.question.on_answer_votes_balance_up self
    end

    UserTopicInfo.vote_removed!(self, v)
    update_question_answered_with
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end

  def ban
    self.question.answer_removed!
    self.set({:banned => true})
  end

  def self.ban(ids)
    self.find_each(:_id.in => ids, :select => [:question_id]) do |answer|
      answer.ban
    end
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  def disable_limits?
    self.user.present? && self.user.can_post_whithout_limits_on?(self.group)
  end

  def disallow_spam
    if new? && !disable_limits?
      eq_answer = Answer.first({:body => self.body,
                                  :question_id => self.question_id,
                                  :group_id => self.group_id
                                })

      last_answer  = Answer.first(:user_id => self.user_id,
                                   :question_id => self.question_id,
                                   :group_id => self.group_id,
                                   :order => "created_at desc")

      valid = (eq_answer.nil? || eq_answer.id == self.id) &&
              ((last_answer.nil?) || (Time.now - last_answer.created_at) > 20)
      if !valid
        self.errors.add(:body, "Your answer looks like spam.")
      end
    end
  end

  def create_news_update
    NewsUpdate.create(:author => self.user, :entry => self,
                      :created_at => self.created_at, :action => 'created')

    hide_news_update
  end
  handle_asynchronously :create_news_update

  def hide_news_update
    self.question.news_update.hide!
  end

  def unhide_news_update
    # if this is the last question, reshow question's news_update
    self.question.news_update.show! if ( self.question && self.question.answers_count == 1 )
  end

  def new_answer_notification
    # Notify those who follow the question about the new answer,
    # except the creator of the answer and those who asked not to
    # receive email notifications about answers.
    #
    # Additionally notify who follows the question lists of the
    # question, should it belong to any.

    watcher_ids_set = Set.new

    self.question.watchers.each do |watcher|
      # `watcher` is already the id.
      watcher_ids_set << watcher
    end

    self.question.topics.each do |topic|
      next unless topic.is_a?(QuestionList)
      topic.followers.each do |follower|
        watcher_ids_set << follower.id
      end
    end

    watcher_ids_set.each do |watcher_id|
      user = User.find_by_id(watcher_id)
      if user != self.user &&
          user.notification_opts.new_answer
        Notifier.delay.new_answer(user, self.group, self, true)
        Notification.create!(:user => user,
                             :event_type => "new_answer",
                             :origin => self.user,
                             :reason => self)
      end
    end
  end
  handle_asynchronously :new_answer_notification

  # Returns the (only) associated news update.
  # We need this because has_one doesn't work.
  def news_update
    news_updates.first
  end

  def increment_user_topic_answers_count
    UserTopicInfo.answer_added!(self)
  end

  def decrement_user_topic_answers_count
    UserTopicInfo.answer_removed!(self)
  end

end
