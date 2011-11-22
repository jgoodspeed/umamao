class UsersWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def recent_users(group)
    group.paginate_users(:order => "created_at desc",
                :per_page => 10,
                :account_type => I18n.t("users.account_type.financial_advisor"),
                :page => 1)
  end

  protected
  def set_name
    self[:name] ||= "users"
  end
end
