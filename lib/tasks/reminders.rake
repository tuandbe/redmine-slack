namespace :redmine_reminder do
  desc "Process and send scheduled reminders"
  task :send_reminders => :environment do
    puts "Starting reminder processing at #{Time.current}"
    
    begin
      sent_count = RedmineReminder::ReminderService.process_reminders
      puts "Reminder processing completed. Sent #{sent_count} reminders."
    rescue => e
      puts "Error processing reminders: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Show upcoming reminders for the next 7 days"
  task :upcoming => :environment do
    puts "Upcoming reminders for the next 7 days:"
    puts "=" * 50
    
    (0..6).each do |days_ahead|
      date = Date.current + days_ahead.days
      puts "\n#{date.strftime('%A, %d/%m/%Y')}:"
      
      reminders = Reminder.active.where(send_date: date)
      if reminders.any?
        reminders.each do |reminder|
          puts "  #{reminder.formatted_send_time} - #{reminder.project.name}: #{truncate_content(reminder.content)}"
          if reminder.is_recurring?
            puts "    (Lặp lại: #{reminder.recurring_type_text})"
          end
        end
      else
        puts "  No reminders scheduled"
      end
    end
  end

  desc "Debug current reminders and time"
  task :debug => :environment do
    puts "=== REMINDER DEBUG INFORMATION ==="
    puts "Current Rails environment: #{Rails.env}"
    puts "Rails timezone: #{Rails.configuration.time_zone}"
    puts "System time: #{Time.current}"
    puts "System timezone: #{Time.current.zone}"
    puts
    
    # Check all users and their timezones
    puts "=== USER TIMEZONES ==="
    User.active.each do |user|
      tz_pref = user.preference&.time_zone
      puts "User: #{user.login} (#{user.firstname} #{user.lastname})"
      puts "  Timezone preference: #{tz_pref.inspect}"
      puts "  Computed timezone: #{RedmineReminder::ReminderService.send(:get_user_timezone, user)}"
      puts
    end
    
    # Check active reminders
    puts "=== ACTIVE REMINDERS ==="
    Reminder.active.includes(:created_by, :project).each do |reminder|
      user_tz = RedmineReminder::ReminderService.send(:get_user_timezone, reminder.created_by)
      current_time_in_user_tz = Time.current.in_time_zone(user_tz)
      
      puts "Reminder ##{reminder.id}"
      puts "  Project: #{reminder.project.name}"
      puts "  Created by: #{reminder.created_by.login}"
      puts "  User timezone: #{user_tz}"
      puts "  Send date: #{reminder.send_date}"
      puts "  Send time: #{reminder.send_time}"
      puts "  Current time in user tz: #{current_time_in_user_tz.strftime('%Y-%m-%d %H:%M')}"
      puts "  Should send today?: #{reminder.should_send_today?(user_tz)}"
      puts "  Time matches?: #{reminder.send_time.in_time_zone(user_tz).strftime('%H:%M') == current_time_in_user_tz.strftime('%H:%M')}"
      puts
    end
  end

  desc "Test Google Chat webhook for a project"
  task :test_webhook, [:project_id] => :environment do |t, args|
    if args[:project_id].blank?
      puts "Usage: rake redmine_reminder:test_webhook[project_id]"
      exit 1
    end

    begin
      project = Project.find(args[:project_id])
      webhook_url = get_test_webhook_url(project)
      
      if webhook_url.blank?
        puts "No Google Chat Webhook URL found for project: #{project.name}"
        exit 1
      end

      puts "Testing webhook for project: #{project.name}"
      puts "Webhook URL: #{webhook_url}"
      
      test_message = "🧪 Test message from Redmine Reminder plugin\nProject: #{project.name}\nTime: #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      
      require 'httpclient'
      client = HTTPClient.new
      client.ssl_config.cert_store.set_default_paths
      client.ssl_config.ssl_version = :auto
      
      response = client.post(webhook_url, { 'text' => test_message }.to_json, 
                            { 'Content-Type' => 'application/json' })
      
      if response.status == 200
        puts "✅ Test message sent successfully!"
      else
        puts "❌ Failed to send test message. HTTP #{response.status}: #{response.body}"
      end
      
    rescue ActiveRecord::RecordNotFound
      puts "Project with ID #{args[:project_id]} not found"
      exit 1
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  private

  def truncate_content(content, length = 50)
    content.length > length ? "#{content[0..length-1]}..." : content
  end

  def get_test_webhook_url(project)
    custom_field = CustomField.find_by(name: 'Google Chat Webhook')
    return nil unless custom_field

    custom_value = project.custom_values.find_by(custom_field: custom_field)
    custom_value&.value
  end
end 
