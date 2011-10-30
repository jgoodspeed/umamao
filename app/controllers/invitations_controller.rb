class InvitationsController < ApplicationController
  before_filter :login_required, :only => [ :pending, :accepted, :resend, :new, :create,
                                            :new_invitation_student, :create_invitation_student ]

  before_filter :check_permissions, :only => [:generate, :generate_invite]

  def pending
    @pending_invitations = Invitation.query(:sender_id => current_user.id,
                                            :accepted_at => nil,
                                            :order => :created_at.desc)
  end

  def accepted
    @accepted_invitations = Invitation.query(:sender_id => current_user.id,
                                             :accepted_at.ne => nil,
                                             :order => :created_at.desc)
  end

  def inquiry
    render :action => 'inquiry', :layout => 'welcome'
  end
  
  def create_inquiry
    @email = params[:email]
    @message = params[:message]

    @errors = []

    if params[:agrees_with_terms_of_service] != "1"
      @errors.push ( t("users.validation.errors.did_not_agree") )
    end
    if @email.empty?
      @errors.push ( t("users.validation.errors.empty_email") )
    end
    if @message.empty?
      @errors.push ( t("users.validation.errors.empty_description") )
    end

    if @errors.present?
      flash[:error]  = t("users.create.flash_error")
      render 'inquiry', :layout => 'welcome'
    else
      Notifier.delay.invitation_inquiry ( @email, @message )
      flash[:notice] = t("welcome", :scope => "invitations.inquiry")

      redirect_to root_path
    end
  end
  
  def new
    set_page_title(t("invitations.new.title"))
    @fetching_contacts = params[:wait].present?
    @has_contacts = current_user.contacts.count > 0

    @pending_invitations =
      current_user.invitations.query(:accepted_at => nil)

    @accepted_invitations =
      current_user.invitations.query(:accepted_at.ne => nil)

    @faulty_emails = flash[:faulty_emails]
  end

  def create
    @emails = params[:emails]
    @message = params[:message]

    count, @faulty_emails =
      current_user.invite!(@emails, current_group, @message)

    if @faulty_emails.present?
      flash[:faulty_emails] = @faulty_emails
    end

    if count && count > 0
      track_event(:sent_invitation, :count => count)
    end

    redirect_to new_invitation_path

  end

  def new_invitation_student
    @course = Course.find_by_slug_or_id(params[:id])
    @student = Student.find_by_id(params[:student_id])

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)
        }
      end
      format.html
    end
  end

  def create_invitation_student
    s = Student.find_by_id(params[:student_id])
    if s.academic_email
      invitation = Invitation.new(:sender_id => current_user.id,
                     :group_id => current_group.id,
                     :message => params[:message],
                     :topic_ids => [params[:course_id]],
                     :recipient_email => s.academic_email)
      invitation.save!
    end

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :message => t("invitations.sent")
        }
      end
    end
  end

  def resend
    invitation = Invitation.find_by_id(params[:id])
    invitation.send_invitation
    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :message => t("invitations.sent")
        }
      end
    end
  end

  def generate
    render :action => 'generate', :layout => 'welcome'
  end

  def generate_invite
    @invitation = Invitation.new( :sender_id => current_user.id,
      :account_type => I18n.t("users.account_type.financial_advisor") )
    @invitation.generate_confirmation_token
    @invitation.save(:validate => false)

    render :action => 'generate', :layout => 'welcome'
  end

protected

  def check_permissions
    unless logged_in? && current_user.role.eql?("admin")
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t("invitations.generate.error")
          redirect_to root_path
        end
      end
    end
  end

end
