class RemindersController < ApplicationController
  before_action :find_project, :authorize
  before_action :find_reminder, only: [:show, :edit, :update, :destroy]

  def index
    @reminders = @project.reminders.includes(:created_by, :issue)
                        .order(created_at: :desc)
    
    respond_to do |format|
      format.html
    end
  end

  def show
  end

  def new
    @reminder = @project.reminders.build
    @reminder.send_date = Date.current
    
    # Set default time in user's timezone
    user_tz = get_user_timezone(User.current)
    Time.use_zone(user_tz) do
      @reminder.send_time = Time.zone.now.change(sec: 0).utc
    end
  end

  def create
    @reminder = @project.reminders.build(reminder_params)
    @reminder.created_by = User.current
    
    # Fix timezone issue: convert send_time to UTC properly
    if params[:reminder][:send_time].present?
      user_tz = get_user_timezone(User.current)
      time_string = params[:reminder][:send_time]
      date_string = params[:reminder][:send_date] || Date.current.to_s
      
      # Parse time in user's timezone and convert to UTC for storage
      Time.use_zone(user_tz) do
        user_time = Time.zone.parse("#{date_string} #{time_string}")
        @reminder.send_time = user_time.utc
      end
    end

    if @reminder.save
      flash[:notice] = l(:notice_reminder_created_successfully)
      redirect_to project_reminders_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    # Fix timezone issue: convert send_time to UTC properly  
    reminder_params_with_time = if params[:reminder][:send_time].present?
      user_tz = get_user_timezone(User.current)
      time_string = params[:reminder][:send_time]
      date_string = params[:reminder][:send_date] || @reminder.send_date.to_s
      
      # Parse time in user's timezone and convert to UTC for storage
      Time.use_zone(user_tz) do
        user_time = Time.zone.parse("#{date_string} #{time_string}")
        reminder_params.merge(send_time: user_time.utc)
      end
    else
      reminder_params
    end
    
    if @reminder.update(reminder_params_with_time)
      flash[:notice] = l(:notice_reminder_updated_successfully)
      redirect_to project_reminders_path(@project)
    else
      render :edit
    end
  end

  def destroy
    @reminder.destroy
    flash[:notice] = l(:notice_reminder_deleted_successfully)
    redirect_to project_reminders_path(@project)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_reminder
    @reminder = @project.reminders.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def reminder_params
    params.require(:reminder).permit(:content, :send_time, :send_date, :is_recurring, 
                                   :recurring_type, :custom_days, :issue_id, :active)
  end

  def get_user_timezone(user)
    # Get user's timezone from preferences
    user_tz = user.preference&.time_zone
    
    # Check if user has a valid timezone set (not nil, not empty string)
    if user_tz.present? && user_tz.strip != ""
      # Map common timezone names to Rails timezone names
      case user_tz.strip
      when 'Hanoi'
        'Asia/Ho_Chi_Minh'
      else
        # Try to find the timezone in ActiveSupport::TimeZone
        if ActiveSupport::TimeZone[user_tz]
          user_tz
        else
          'Asia/Ho_Chi_Minh'
        end
      end
    else
      # Fallback to Redmine's default users timezone setting
      default_tz = Setting.default_users_time_zone
      
      if default_tz.present? && default_tz.strip != ""
        # Map common timezone names if needed
        case default_tz.strip
        when 'Hanoi'
          'Asia/Ho_Chi_Minh'
        else
          # Try to find the timezone in ActiveSupport::TimeZone
          if ActiveSupport::TimeZone[default_tz]
            default_tz
          else
            'Asia/Ho_Chi_Minh'
          end
        end
      else
        # Final fallback to Vietnam timezone
        'Asia/Ho_Chi_Minh'
      end
    end
  end
end 
