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

  RECURRING_TYPES = {
    'daily' => 'Hàng ngày',
    'weekdays' => 'Mỗi ngày làm việc',
    'weekly' => 'Hàng tuần',
    'custom' => 'Tuỳ chỉnh'
  }.freeze

  WEEKDAYS = {
    '1' => 'Thứ 2',
    '2' => 'Thứ 3', 
    '3' => 'Thứ 4',
    '4' => 'Thứ 5',
    '5' => 'Thứ 6',
    '6' => 'Thứ 7',
    '0' => 'Chủ nhật'
  }.freeze

  def formatted_send_time(timezone = nil)
    tz = timezone || get_user_timezone
    send_time.in_time_zone(tz).strftime('%H:%M')
  end

  def formatted_send_date
    send_date.strftime('%d/%m/%Y')
  end

  def recurring_type_text
    RECURRING_TYPES[recurring_type] || 'Không lặp lại'
  end

  def custom_days_text
    return '' unless recurring_type == 'custom' && custom_days.present?
    
    days = custom_days.split(',').map(&:strip)
    days.map { |day| WEEKDAYS[day] }.compact.join(', ')
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
    # Get user's timezone from preferences
    user_tz = created_by.preference&.time_zone
    
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
      errors.add(:custom_days, 'không được để trống khi chọn lặp lại tuỳ chỉnh')
      return
    end

    days = custom_days.split(',').map(&:strip)
    invalid_days = days.reject { |day| WEEKDAYS.key?(day) }
    
    if invalid_days.any?
      errors.add(:custom_days, "chứa ngày không hợp lệ: #{invalid_days.join(', ')}")
    end
  end
end 
