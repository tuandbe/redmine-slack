# Quy ước lập trình và chiến lược Git - Plugin Redmine Reminder

## Quy ước lập trình

### 1. Ruby Style Guide

Plugin tuân theo [Ruby Style Guide](https://rubystyle.guide/) và các quy ước của Redmine core.

#### Naming Conventions
```ruby
# Classes và Modules - PascalCase
class ReminderService
module RedmineReminder::Patches

# Methods và Variables - snake_case
def send_reminder_notification
reminder_service = ReminderService.new

# Constants - SCREAMING_SNAKE_CASE
WEBHOOK_TIMEOUT = 30.seconds
DEFAULT_TIMEZONE = 'Asia/Ho_Chi_Minh'

# Files và Directories - snake_case
reminder_service.rb
redmine_reminder/patches/
```

#### Code Structure
```ruby
# Class structure order:
class Reminder < ActiveRecord::Base
  # 1. Constants
  RECURRING_TYPES = %w[daily weekdays weekly custom].freeze
  
  # 2. Includes/Extends
  include SomeModule
  
  # 3. Associations
  belongs_to :project
  belongs_to :created_by, class_name: 'User'
  
  # 4. Validations
  validates :content, presence: true
  validates :send_time, presence: true
  
  # 5. Scopes
  scope :active, -> { where(active: true) }
  scope :for_today, -> { where(send_date: Date.current) }
  
  # 6. Callbacks
  before_save :set_default_timezone
  after_create :schedule_reminder
  
  # 7. Class methods
  def self.recurring_type_options
    # implementation
  end
  
  # 8. Instance methods
  def should_send_today?
    # implementation
  end
  
  private
  
  # 9. Private methods
  def validate_custom_days
    # implementation
  end
end
```

### 2. Rails Conventions

#### Model Guidelines
```ruby
# Sử dụng ActiveRecord associations thay vì manual joins
# Good
reminder.project.name
reminder.issue&.subject

# Bad
Project.find(reminder.project_id).name

# Sử dụng scopes cho reusable queries
# Good
Reminder.active.for_today

# Bad
Reminder.where(active: true).where(send_date: Date.current)

# Validation messages trong locale files
validates :content, presence: { message: I18n.t('error_content_blank') }
```

#### Controller Guidelines
```ruby
# Strong parameters
def reminder_params
  params.require(:reminder).permit(:content, :send_time, :send_date, 
                                   :is_recurring, :recurring_type, 
                                   :custom_days, :issue_id, :active)
end

# Authorization trong before_action
before_action :find_project, :authorize

# Error handling
def create
  if @reminder.save
    flash[:notice] = l(:notice_reminder_created_successfully)
    redirect_to project_reminders_path(@project)
  else
    render :new
  end
end
```

#### View Guidelines
```erb
<!-- Sử dụng helpers cho formatting -->
<%= formatted_time(@reminder.send_time, @user.time_zone) %>

<!-- Internationalization -->
<%= l(:label_reminder_content) %>

<!-- Form helpers với proper classes -->
<%= f.text_area :content, class: 'wiki-edit', rows: 10 %>

<!-- Consistent styling với Redmine theme -->
<div class="box tabular">
  <p><%= f.label :content %><%= f.text_area :content %></p>
</div>
```

### 3. Database Conventions

#### Migration Guidelines
```ruby
class CreateReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :reminders do |t|
      # Primary key tự động tạo
      
      # Foreign keys với proper naming
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :issue, null: true, foreign_key: true
      
      # Content fields
      t.text :content, null: false
      
      # Date/time fields
      t.date :send_date, null: false
      t.time :send_time, null: false
      
      # Boolean fields với default values
      t.boolean :is_recurring, default: false
      t.boolean :active, default: true
      
      # Enum-like fields
      t.string :recurring_type, limit: 20
      t.string :custom_days, limit: 20
      
      # Timestamps
      t.timestamps
    end
    
    # Indexes cho performance
    add_index :reminders, [:project_id, :send_date, :send_time]
    add_index :reminders, :active
  end
end
```

### 4. Testing Conventions

#### Test Structure
```ruby
# test/unit/reminder_test.rb
require File.expand_path('../../test_helper', __FILE__)

class ReminderTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues, :reminders
  
  def setup
    @project = Project.find(1)
    @user = User.find(1)
    @reminder = Reminder.new(
      project: @project,
      created_by: @user,
      content: 'Test reminder',
      send_date: Date.current,
      send_time: Time.current
    )
  end
  
  def test_should_create_valid_reminder
    assert @reminder.save
  end
  
  def test_should_require_content
    @reminder.content = ''
    assert_not @reminder.valid?
    assert_includes @reminder.errors[:content], "can't be blank"
  end
end
```

### 5. Documentation Conventions

#### Code Comments
```ruby
# Use descriptive comments for complex business logic
# Calculate next send date based on recurring type and user timezone
def next_send_date(timezone = nil)
  return nil unless is_recurring?
  
  # Use specified timezone or get from user preferences
  tz = timezone || get_user_timezone
  today = Time.current.in_time_zone(tz).to_date
  
  case recurring_type
  when 'daily'
    # Send every day
    today + 1.day
  when 'weekdays'
    # Send only Monday to Friday
    next_weekday = today + 1.day
    while next_weekday.wday == 0 || next_weekday.wday == 6
      next_weekday += 1.day
    end
    next_weekday
  # ... other cases
  end
end
```

#### README Documentation
- Luôn có README.md với setup instructions
- Include code examples cho common use cases
- Document API endpoints nếu có
- Include troubleshooting section

### 6. Internationalization (I18n)

#### Locale File Structure
```yaml
# config/locales/en.yml
en:
  # Labels - giao diện người dùng
  label_reminder: "Reminder"
  label_reminder_content: "Content"
  label_send_date: "Send Date"
  
  # Field labels
  field_content: "Content"
  field_send_time: "Send Time"
  
  # Button labels
  button_create_reminder: "Create Reminder"
  button_edit_reminder: "Edit"
  
  # Notice messages
  notice_reminder_created_successfully: "Reminder was successfully created."
  notice_reminder_updated_successfully: "Reminder was successfully updated."
  
  # Error messages
  error_content_blank: "Content cannot be blank"
  error_webhook_failed: "Failed to send webhook notification"
  
  # Recurring types
  recurring_type_daily: "Daily"
  recurring_type_weekdays: "Weekdays (Mon-Fri)"
  recurring_type_weekly: "Weekly"
  recurring_type_custom: "Custom days"
```

#### Usage trong Code
```ruby
# Controllers
flash[:notice] = l(:notice_reminder_created_successfully)

# Views
<%= l(:label_reminder_content) %>

# Models
validates :content, presence: { message: l(:error_content_blank) }
```

## Chiến lược Git

### 1. Branch Strategy

#### GitFlow Workflow
```
main (production-ready)
├── develop (integration branch)
│   ├── feature/reminder-recurring-patterns
│   ├── feature/google-chat-integration
│   ├── feature/timezone-handling
│   └── hotfix/webhook-timeout-fix
└── release/v0.4.0
```

#### Branch Naming Conventions
```bash
# Feature branches
feature/issue-autocomplete
feature/recurring-reminders
feature/slack-integration

# Bug fixes
bugfix/timezone-conversion-error
bugfix/webhook-retry-logic

# Hotfixes (urgent production fixes)
hotfix/security-patch-webhook-validation
hotfix/cron-job-memory-leak

# Release branches
release/v0.4.0
release/v0.5.0
```

### 2. Commit Message Conventions

#### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types
- `feat`: Tính năng mới
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, semicolons, etc)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Build tasks, package manager configs

#### Examples
```bash
feat(reminders): add recurring reminder functionality

- Implement daily, weekdays, weekly, and custom recurring options
- Add validation for custom days pattern
- Update database schema with recurring_type and custom_days fields

Closes #123

fix(webhook): handle timeout errors gracefully

- Add retry mechanism with exponential backoff
- Log webhook failures for debugging
- Return proper error messages to users

Fixes #456

docs(readme): update installation instructions

- Add section for custom field configuration
- Include troubleshooting guide
- Update webhook setup examples
```

### 3. Pull Request Guidelines

#### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots for UI changes]

## Checklist
- [ ] Code follows project coding standards
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings or errors introduced
```

#### Review Process
1. **Self-review**: Developer reviews own code
2. **Peer review**: At least one team member reviews
3. **Testing**: All tests must pass
4. **Documentation**: Update docs if needed
5. **Merge**: Squash commits when merging to keep history clean

### 4. Release Process

#### Version Numbering (Semantic Versioning)
```
MAJOR.MINOR.PATCH

Examples:
0.4.0 - Minor release with new features
0.4.1 - Patch release with bug fixes
1.0.0 - Major release (breaking changes)
```

#### Release Checklist
```bash
# 1. Create release branch
git checkout develop
git pull origin develop
git checkout -b release/v0.4.0

# 2. Update version numbers
# - Update init.rb version
# - Update CHANGELOG.md
# - Update documentation if needed

# 3. Final testing
bundle exec rake test
bundle exec rake redmine:plugins:migrate RAILS_ENV=test

# 4. Merge to main
git checkout main
git merge --no-ff release/v0.4.0

# 5. Tag release
git tag -a v0.4.0 -m "Release version 0.4.0"

# 6. Push changes
git push origin main
git push origin v0.4.0

# 7. Merge back to develop
git checkout develop
git merge --no-ff release/v0.4.0
git push origin develop

# 8. Delete release branch
git branch -d release/v0.4.0
```

### 5. Code Quality Tools

#### RuboCop Configuration
```yaml
# .rubocop.yml
inherit_from: ../../.rubocop.yml  # Inherit from Redmine core

AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'tmp/**/*'
  NewCops: enable

Style/Documentation:
  Enabled: false  # Disable for plugin development

Layout/LineLength:
  Max: 120

Metrics/MethodLength:
  Max: 15

Metrics/ClassLength:
  Max: 100
```

#### Pre-commit Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run RuboCop
bundle exec rubocop --auto-correct

# Run tests
bundle exec rake test

# Check for debugging statements
if grep -r "binding.pry\|debugger\|console.log" app/ lib/ --exclude-dir=vendor; then
  echo "Remove debugging statements before committing"
  exit 1
fi
```

### 6. Security Practices

#### Sensitive Data Handling
```ruby
# Không commit webhook URLs hoặc sensitive config
# Sử dụng environment variables hoặc encrypted credentials

# Good
webhook_url = Rails.application.credentials.google_chat_webhook_url

# Bad
webhook_url = "https://chat.googleapis.com/v1/spaces/..."
```

#### Input Validation
```ruby
# Validate tất cả user inputs
validates :content, presence: true, length: { maximum: 1000 }
validates :send_date, presence: true
validate :webhook_url_format

private

def webhook_url_format
  return unless webhook_url.present?
  unless webhook_url =~ URI::regexp(['http', 'https'])
    errors.add(:webhook_url, 'must be a valid URL')
  end
end
```

### 7. Performance Guidelines

#### Database Queries
```ruby
# Avoid N+1 queries
# Good
@reminders = @project.reminders.includes(:created_by, :issue)

# Bad
@reminders = @project.reminders
# Then trong view: @reminders.each { |r| r.created_by.name }

# Use proper indexes
add_index :reminders, [:project_id, :send_date, :active]

# Efficient date queries
Reminder.where(send_date: Date.current)
# Thay vì: Reminder.where("DATE(send_date) = ?", Date.current)
```

#### Memory Management
```ruby
# Process large datasets in batches
Reminder.active.find_each(batch_size: 100) do |reminder|
  ReminderService.new.send_notification(reminder)
end

# Cleanup resources trong background jobs
def send_reminders
  # ... processing
ensure
  # Cleanup connections, temp files, etc.
  ActiveRecord::Base.clear_active_connections!
end
``` 
