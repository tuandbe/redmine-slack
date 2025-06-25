# Devin Specific - Plugin Redmine Reminder

## Cấu hình Devin cho Redmine Plugin Development

### Development Environment Setup

Devin cần hiểu về môi trường phát triển Redmine plugin:

```bash
# Ruby version
ruby 3.0.6

# Rails version  
rails 6.1.7.6

# Redmine version
5.0.6.stable

# Database
MySQL/PostgreSQL

# Web server
Nginx với server blocks
```

### Project Structure Understanding

Devin cần hiểu cấu trúc thư mục của Redmine plugin:

```
plugins/redmine_reminder/
├── app/
│   ├── controllers/         # Rails controllers
│   │   └── reminders_controller.rb
│   ├── models/             # ActiveRecord models
│   │   └── reminder.rb
│   ├── views/              # ERB templates
│   │   └── reminders/
│   └── helpers/            # View helpers
├── assets/                 # CSS, JS, images
│   ├── javascripts/
│   ├── stylesheets/
│   └── images/
├── config/                 # Configuration files
│   ├── locales/           # I18n translations
│   │   ├── en.yml
│   │   ├── vi.yml
│   │   └── ja.yml
│   └── routes.rb          # Plugin routes
├── db/                    # Database migrations
│   └── migrate/
├── lib/                   # Library code
│   ├── tasks/            # Rake tasks
│   └── redmine_reminder/  # Plugin modules
├── test/                 # Test files
├── init.rb              # Plugin initialization
├── Gemfile              # Plugin dependencies
└── README.md            # Documentation
```

### Key Development Patterns

#### 1. Model Development
```ruby
# Standard Redmine plugin model pattern
class Reminder < ActiveRecord::Base
  # Always include project association
  belongs_to :project
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  
  # Optional issue association
  belongs_to :issue, optional: true
  
  # Essential validations
  validates :content, presence: true
  validates :send_time, presence: true
  validates :send_date, presence: true
  
  # Useful scopes
  scope :active, -> { where(active: true) }
  scope :for_today, -> { where(send_date: Date.current) }
  
  # Business logic methods
  def should_send_today?(timezone = nil)
    # Implementation với timezone handling
  end
end
```

#### 2. Controller Development
```ruby
# Standard Redmine controller pattern
class RemindersController < ApplicationController
  # Essential before_actions
  before_action :find_project, :authorize
  before_action :find_reminder, only: [:show, :edit, :update, :destroy]
  
  # Standard CRUD actions
  def index
    @reminders = @project.reminders.includes(:created_by, :issue)
                        .order(created_at: :desc)
  end
  
  def create
    @reminder = @project.reminders.build(reminder_params)
    @reminder.created_by = User.current
    
    if @reminder.save
      flash[:notice] = l(:notice_reminder_created_successfully)
      redirect_to project_reminders_path(@project)
    else
      render :new
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def reminder_params
    params.require(:reminder).permit(:content, :send_time, :send_date, 
                                   :is_recurring, :recurring_type, 
                                   :custom_days, :issue_id, :active)
  end
end
```

#### 3. View Development
```erb
<!-- Standard Redmine view pattern -->
<div class="contextual">
  <%= link_to l(:label_new_reminder), 
              new_project_reminder_path(@project), 
              class: 'icon icon-add' %>
</div>

<h2><%= l(:label_reminders) %></h2>

<div class="autoscroll">
  <table class="list">
    <thead>
      <tr>
        <th><%= l(:field_content) %></th>
        <th><%= l(:field_send_date) %></th>
        <th><%= l(:field_send_time) %></th>
        <th><%= l(:field_active) %></th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @reminders.each do |reminder| %>
      <tr class="<%= cycle('odd', 'even') %>">
        <td><%= truncate(reminder.content, length: 50) %></td>
        <td><%= reminder.formatted_send_date %></td>
        <td><%= reminder.formatted_send_time %></td>
        <td><%= reminder.active? ? l(:general_text_yes) : l(:general_text_no) %></td>
        <td class="buttons">
          <%= link_to l(:button_edit), 
                      edit_project_reminder_path(@project, reminder),
                      class: 'icon icon-edit' %>
          <%= link_to l(:button_delete),
                      project_reminder_path(@project, reminder),
                      method: :delete,
                      confirm: l(:text_are_you_sure),
                      class: 'icon icon-del' %>
        </td>
      </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Service Classes

```ruby
# Service class pattern for complex business logic
class ReminderService
  def initialize(reminder)
    @reminder = reminder
  end
  
  def send_notification
    return false unless should_send?
    
    webhook_url = get_webhook_url
    return false if webhook_url.blank?
    
    begin
      response = send_webhook(webhook_url, build_message)
      log_result(response)
      true
    rescue => e
      Rails.logger.error "Webhook failed: #{e.message}"
      false
    end
  end
  
  private
  
  def should_send?
    @reminder.active? && @reminder.should_send_today?
  end
  
  def get_webhook_url
    custom_field = CustomField.find_by(name: 'Google Chat Webhook')
    return nil unless custom_field
    
    @reminder.project.custom_value_for(custom_field)&.value
  end
  
  def build_message
    {
      text: format_message(@reminder.content)
    }
  end
  
  def send_webhook(url, payload)
    HTTPClient.new.post(url, payload.to_json, {
      'Content-Type' => 'application/json'
    })
  end
end
```

### Testing Patterns

```ruby
# Unit test pattern
require File.expand_path('../../test_helper', __FILE__)

class ReminderTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues, :reminders
  
  def setup
    @project = Project.find(1)
    @user = User.find(1)
    @reminder = reminders(:reminder_001)
  end
  
  def test_should_create_valid_reminder
    reminder = Reminder.new(
      project: @project,
      created_by: @user,
      content: 'Test reminder',
      send_date: Date.current,
      send_time: Time.current
    )
    
    assert reminder.save
  end
  
  def test_should_require_content
    @reminder.content = ''
    assert_not @reminder.valid?
    assert_includes @reminder.errors[:content], "can't be blank"
  end
  
  def test_should_send_today_for_matching_date
    @reminder.update(send_date: Date.current, active: true)
    assert @reminder.should_send_today?
  end
end
```

### Background Jobs Pattern

```ruby
# Rake task for background processing
namespace :redmine_reminder do
  desc 'Send due reminders'
  task :send_reminders => :environment do
    Rails.logger.info "Starting reminder sending task"
    
    current_time = Time.current
    current_date = current_time.to_date
    current_hour_minute = current_time.strftime('%H:%M')
    
    # Find reminders that should be sent now
    reminders = Reminder.active
                      .where(send_date: current_date)
                      .where("TIME(send_time) = ?", current_hour_minute)
    
    sent_count = 0
    failed_count = 0
    
    reminders.find_each do |reminder|
      if ReminderService.new(reminder).send_notification
        sent_count += 1
        Rails.logger.info "Sent reminder #{reminder.id}"
        
        # Update recurring reminders
        if reminder.is_recurring?
          next_date = reminder.next_send_date
          reminder.update(send_date: next_date) if next_date
        end
      else
        failed_count += 1
        Rails.logger.error "Failed to send reminder #{reminder.id}"
      end
    end
    
    Rails.logger.info "Reminder task completed: #{sent_count} sent, #{failed_count} failed"
  end
end
```

### Database Migration Patterns

```ruby
class CreateReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :reminders do |t|
      # Foreign keys
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :issue, null: true, foreign_key: true
      
      # Content
      t.text :content, null: false
      
      # Scheduling
      t.date :send_date, null: false
      t.time :send_time, null: false
      
      # Recurring options
      t.boolean :is_recurring, default: false
      t.string :recurring_type, limit: 20
      t.string :custom_days, limit: 20
      
      # Status
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    # Performance indexes
    add_index :reminders, [:project_id, :send_date, :send_time]
    add_index :reminders, [:active, :send_date]
    add_index :reminders, :project_id
  end
end
```

### Plugin Initialization Pattern

```ruby
# init.rb - Plugin registration
require 'redmine'

# Load plugin modules
require File.expand_path('../lib/redmine_reminder/hooks_listener', __FILE__)
require File.expand_path('../lib/redmine_reminder/reminder_service', __FILE__)

Redmine::Plugin.register :redmine_reminder do
  name 'Redmine Reminder'
  author 'Your Name'
  description 'Reminder functionality with Google Chat/Slack integration'
  version '0.4.0'
  url 'https://github.com/yourname/redmine_reminder'
  
  requires_redmine version_or_higher: '5.0.0'
  
  # Project module
  project_module :reminders do
    permission :view_reminders, { :reminders => [:index, :show, :search_issues] }
    permission :manage_reminders, { :reminders => [:new, :create, :edit, :update, :destroy] }
  end
  
  # Menu integration
  menu :project_menu, :reminders, 
       { controller: 'reminders', action: 'index' },
       caption: 'Reminder', 
       after: :activity, 
       param: :project_id
       
  # Settings
  settings default: {
    'default_send_time' => '09:00',
    'webhook_timeout' => 30
  }, partial: 'settings/reminder_settings'
end

# Apply patches
Rails.configuration.to_prepare do
  unless Project.included_modules.include?(RedmineReminder::ProjectPatch)
    Project.send(:include, RedmineReminder::ProjectPatch)
  end
end
```

### Common Development Tasks for Devin

1. **Tạo tính năng mới**: Implement new reminder types (email, SMS, etc.)
2. **Cải thiện UI**: Enhance user interface với modern JavaScript
3. **Tối ưu performance**: Database query optimization và caching
4. **Testing**: Comprehensive test coverage
5. **Documentation**: Update README và inline documentation
6. **Security**: Input validation và authorization improvements
7. **Internationalization**: Add new language support
8. **Integration**: Connect với external services
9. **Bug fixes**: Resolve reported issues
10. **Refactoring**: Code cleanup và modernization

### Error Handling Patterns

```ruby
# Controller error handling
def create
  begin
    @reminder = @project.reminders.build(reminder_params)
    @reminder.created_by = User.current
    
    if @reminder.save
      flash[:notice] = l(:notice_reminder_created_successfully)
      redirect_to project_reminders_path(@project)
    else
      flash.now[:error] = @reminder.errors.full_messages.join(', ')
      render :new
    end
  rescue => e
    Rails.logger.error "Error creating reminder: #{e.message}"
    flash.now[:error] = l(:error_reminder_creation_failed)
    render :new
  end
end

# Service error handling
def send_notification
  begin
    # Implementation
  rescue Net::TimeoutError => e
    Rails.logger.error "Webhook timeout: #{e.message}"
    false
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    false
  rescue => e
    Rails.logger.error "Unexpected error: #{e.message}"
    false
  end
end
```

### Performance Optimization Guidelines

1. **Database Queries**: Sử dụng includes(), joins() appropriately
2. **Caching**: Implement caching cho expensive operations
3. **Background Jobs**: Move heavy processing to background
4. **Memory Management**: Avoid memory leaks trong rake tasks
5. **HTTP Timeouts**: Set appropriate timeouts cho webhooks
6. **Pagination**: Implement pagination cho large datasets
7. **Indexes**: Add database indexes cho frequent queries 
