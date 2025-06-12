class Reminder < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  belongs_to :issue, optional: true

  validates :content, presence: true
  validates :send_time, presence: true
  validates :send_date, presence: true
  validates :recurring_type, inclusion: { in: %w[daily weekdays weekly custom] }, allow_blank: true
  validate :validate_custom_days

  scope :active, -> { where(active: true) }
  scope :for_today, -> { where(send_date: Date.current) }
  scope :for_time, ->(time) { where(send_time: time) }

  def self.recurring_type_options
    %w[daily weekdays weekly custom].map do |type|
      [I18n.t("recurring_type_#{type}"), type]
    end
  end

  def self.weekday_options
    %w[monday tuesday wednesday thursday friday saturday sunday].map.with_index do |day, index|
      [I18n.t("weekday_#{day}"), (index + 1) % 7]
    end
  end

  def formatted_send_time(timezone = nil)
    tz = timezone || get_user_timezone
    send_time.in_time_zone(tz).strftime('%H:%M')
  end

  def formatted_send_date
    send_date.strftime('%d/%m/%Y')
  end

  def recurring_type_text
    return I18n.t('label_not_recurring') if recurring_type.blank?
    I18n.t("recurring_type_#{recurring_type}")
  end

  def custom_days_text
    return '' unless recurring_type == 'custom' && custom_days.present?
    
    weekday_map = Hash[Reminder.weekday_options.map { |label, value| [value.to_s, label] }]
    days = custom_days.split(',').map(&:strip)
    days.map { |day| weekday_map[day] }.compact.join(', ')
  end

  def should_send_today?(timezone = nil)
    return false unless active?
    
    # Use specified timezone or get from user
    tz = timezone || get_user_timezone
    today = Time.current.in_time_zone(tz).to_date
    return false unless send_date <= today

    if is_recurring?
      case recurring_type
      when 'daily'
        true
      when 'weekdays'
        (1..5).include?(today.wday)
      when 'weekly'
        today.wday == send_date.wday
      when 'custom'
        custom_days.present? && custom_days.split(',').include?(today.wday.to_s)
      else
        false
      end
    else
      send_date == today
    end
  end

  def next_send_date(timezone = nil)
    return nil unless is_recurring?
    
    # Use specified timezone or get from user
    tz = timezone || get_user_timezone
    today = Time.current.in_time_zone(tz).to_date
    
    case recurring_type
    when 'daily'
      today + 1.day
    when 'weekdays'
      next_weekday = today + 1.day
      while next_weekday.wday == 0 || next_weekday.wday == 6
        next_weekday += 1.day
      end
      next_weekday
    when 'weekly'
      today + 1.week
    when 'custom'
      return nil unless custom_days.present?
      
      days = custom_days.split(',').map(&:to_i).sort
      current_wday = today.wday
      
      # Find next day in the same week
      next_day = days.find { |day| day > current_wday }
      if next_day
        today + (next_day - current_wday).days
      else
        # Next occurrence is in the following week
        today + (7 - current_wday + days.first).days
      end
    end
  end

  private

  def get_user_timezone
    # Determine the user: current user for new reminders, creator for existing ones.
    user = new_record? ? User.current : created_by

    # Get user's timezone from preferences
    user_tz = user&.preference&.time_zone
    
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

  def validate_custom_days
    return unless recurring_type == 'custom'
    
    if custom_days.blank?
      errors.add(:custom_days, I18n.t('error_custom_days_blank'))
      return
    end

    valid_days = Reminder.weekday_options.map { |_, value| value.to_s }
    days = custom_days.split(',').map(&:strip)
    invalid_days = days.reject { |day| valid_days.include?(day) }
    
    if invalid_days.any?
      errors.add(:custom_days, "#{I18n.t('error_custom_days_invalid')}: #{invalid_days.join(', ')}")
    end
  end
end 
