require 'httpclient'

module RedmineReminder
  class ReminderService
      def self.process_reminders
    Rails.logger.info "ReminderService: Starting reminder processing"
      
      # Find all projects with Google Chat Webhook configured
      projects_with_webhook = Project.joins(:custom_values)
                                   .joins('JOIN custom_fields ON custom_values.custom_field_id = custom_fields.id')
                                   .where('custom_fields.name = ? AND custom_values.value IS NOT NULL AND custom_values.value != ?', 
                                          'Google Chat Webhook', '')
                                   .distinct

      Rails.logger.info "ReminderService: Found #{projects_with_webhook.count} projects with webhook"

      reminders_sent = 0

      projects_with_webhook.each do |project|
        webhook_url = get_google_chat_webhook_url(project)
        next if webhook_url.blank?

        # Find active reminders for today and current time
        all_reminders = project.reminders.active.includes(:created_by)
        Rails.logger.info "ReminderService: Project #{project.name} has #{all_reminders.count} active reminders total"
        
        reminders_to_send = []
        
        all_reminders.each do |reminder|
          # Get user's timezone, fallback to system default
          user_timezone = get_user_timezone(reminder.created_by)
          current_time_in_user_tz = Time.current.in_time_zone(user_timezone)
          current_time_formatted = current_time_in_user_tz.strftime('%H:%M')
          
          # Convert reminder send_time to user's timezone for comparison
          reminder_time_in_user_tz = reminder.send_time.in_time_zone(user_timezone).strftime('%H:%M')
          
          Rails.logger.info "ReminderService: Checking reminder #{reminder.id} (user: #{reminder.created_by.login}, tz: #{user_timezone})"
          Rails.logger.info "ReminderService: #{reminder_time_in_user_tz} vs #{current_time_formatted}"
          
          if reminder_time_in_user_tz == current_time_formatted && reminder.should_send_today?(user_timezone)
            reminders_to_send << reminder
            Rails.logger.info "ReminderService: Reminder #{reminder.id} scheduled to send"
          end
        end

        Rails.logger.info "ReminderService: Project #{project.name} has #{reminders_to_send.count} reminders to send"

        reminders_to_send.each do |reminder|
          begin
            send_reminder_to_google_chat(reminder, webhook_url)
            reminders_sent += 1
            Rails.logger.info "ReminderService: Successfully sent reminder #{reminder.id}"
            
            # Update send_date for next occurrence if recurring
            user_timezone = get_user_timezone(reminder.created_by)
            update_reminder_next_send_date(reminder, user_timezone)
            
          rescue => e
            Rails.logger.error "ReminderService: Error sending reminder #{reminder.id}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end

      Rails.logger.info "ReminderService: Completed processing. Sent #{reminders_sent} reminders"
      reminders_sent
    end

      private

  def self.get_user_timezone(user)
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
        mapped_tz = case default_tz.strip
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
        Rails.logger.info "ReminderService: User #{user.login} has no timezone (#{user_tz.inspect}), using Redmine default: #{mapped_tz}"
        mapped_tz
      else
        # Final fallback to Vietnam timezone
        fallback_tz = 'Asia/Ho_Chi_Minh'
        Rails.logger.info "ReminderService: User #{user.login} has no timezone and no Redmine default, using fallback: #{fallback_tz}"
        fallback_tz
      end
    end
  end

  def self.get_google_chat_webhook_url(project)
      custom_field = CustomField.find_by(name: 'Google Chat Webhook')
      return nil unless custom_field

      custom_value = project.custom_values.find_by(custom_field: custom_field)
      custom_value&.value
    end

    def self.send_reminder_to_google_chat(reminder, webhook_url)
      message = format_reminder_message(reminder)
      
      begin
        client = HTTPClient.new
        client.ssl_config.cert_store.set_default_paths
        client.ssl_config.ssl_version = :auto
        
        response = client.post(webhook_url, { 'text' => message }.to_json, 
                              { 'Content-Type' => 'application/json' })
        
        unless response.status == 200
          raise "HTTP #{response.status}: #{response.body}"
        end
        
      rescue => e
        Rails.logger.error "ReminderService: Failed to send to Google Chat: #{e.message}"
        raise e
      end
    end

      def self.format_reminder_message(reminder)
        # Convert Redmine's markdown to Google Chat's format
        content = reminder.content
                          .gsub(/\*\*(.*?)\*\*/, '*\1*')      # Bold: **text** -> *text*
                          .gsub(/_(.*?)_/, '_\1_')           # Italic: _text_ -> _text_ (no change)
                          .gsub(/~(.*?)~/, '~\1~')           # Strikethrough: ~text~ -> ~text~ (no change)
                          .gsub(/\[(.*?)\]\((.*?)\)/, '<\2|\1>') # Link: [text](url) -> <url|text>
                          .strip

        message_parts = []
        message_parts << I18n.t('gchat_notification_title', project_name: reminder.project.name)
        message_parts << ""
        message_parts << content
        
        if reminder.issue
          issue_url = generate_issue_url(reminder.issue)
          message_parts << ""
          message_parts << I18n.t('gchat_notification_issue', issue_url: issue_url, issue_id: reminder.issue.id, issue_subject: reminder.issue.subject)
        end

        message_parts << ""
        message_parts << I18n.t('gchat_notification_time', date: reminder.formatted_send_date, time: reminder.formatted_send_time)
        
        if reminder.is_recurring?
          message_parts << I18n.t('gchat_notification_recurring', type: reminder.recurring_type_text)
          if reminder.recurring_type == 'custom'
            message_parts << I18n.t('gchat_notification_custom_days', days: reminder.custom_days_text)
          end
        end

        message_parts.join("\n")
      end

    def self.generate_issue_url(issue)
      if Setting.host_name.present?
        protocol = Setting.protocol.present? ? Setting.protocol : 'http'
        "#{protocol}://#{Setting.host_name}/issues/#{issue.id}"
      else
        "/issues/#{issue.id}"
      end
    end

      def self.update_reminder_next_send_date(reminder, timezone)
    return unless reminder.is_recurring?

    next_date = reminder.next_send_date(timezone)
    if next_date
      reminder.update_column(:send_date, next_date)
      Rails.logger.info "ReminderService: Updated reminder #{reminder.id} next send date to #{next_date}"
    end
  end
  end
end 
