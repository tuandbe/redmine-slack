# Kiến trúc hệ thống - Plugin Redmine Reminder

## Tổng quan kiến trúc

Plugin Redmine Reminder được thiết kế theo mô hình MVC của Ruby on Rails, tích hợp sâu vào Redmine core thông qua plugin architecture. Hệ thống bao gồm các thành phần chính: Models, Controllers, Views, Services, và Background Jobs.

## Sơ đồ kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────┐
│                    Redmine Core                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Project   │  │    Issue    │  │    User     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────┬───────────────────────────────────┘
                          │ Extends via Patches
┌─────────────────────────▼───────────────────────────────────┐
│              Redmine Reminder Plugin                       │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │   Controllers   │    │     Models      │               │
│  │                 │    │                 │               │
│  │ RemindersCtrl   │    │    Reminder     │               │
│  │                 │    │                 │               │
│  └─────────────────┘    └─────────────────┘               │
│           │                       │                        │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │     Views       │    │    Services     │               │
│  │                 │    │                 │               │
│  │ ERB Templates   │    │ ReminderService │               │
│  │ + JavaScript    │    │    Listener     │               │
│  └─────────────────┘    └─────────────────┘               │
│                                   │                        │
│  ┌─────────────────────────────────▼─────────────────────┐ │
│  │             Background Jobs                           │ │
│  │                                                       │ │
│  │  Rake Task: redmine_reminder:send_reminders          │ │
│  │  ↓                                                    │ │
│  │  Cron Job (every minute)                             │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTP Webhooks
┌─────────────────────────▼───────────────────────────────────┐
│              External Services                              │
│                                                             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │  Google Chat    │              │     Slack       │      │
│  │   Webhooks      │              │      API        │      │
│  └─────────────────┘              └─────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Chi tiết các thành phần

### 1. Models Layer

#### Reminder Model
```ruby
class Reminder < ActiveRecord::Base
  # Associations
  belongs_to :project
  belongs_to :created_by, class_name: 'User'
  belongs_to :issue, optional: true
  
  # Key attributes:
  # - content: Text message content
  # - send_date: Date to send reminder
  # - send_time: Time to send (stored in UTC)
  # - is_recurring: Boolean flag
  # - recurring_type: 'daily', 'weekdays', 'weekly', 'custom'
  # - custom_days: CSV string for custom recurring days
  # - active: Boolean flag to enable/disable
```

**Trách nhiệm chính:**
- Quản lý dữ liệu nhắc nhở
- Logic xác định ngày gửi tiếp theo cho recurring reminders
- Timezone handling và conversion
- Validation cho recurring patterns

**Key Methods:**
- `should_send_today?(timezone)`: Xác định có nên gửi nhắc nhở hôm nay không
- `next_send_date(timezone)`: Tính ngày gửi tiếp theo cho recurring reminders
- `formatted_send_time(timezone)`: Format thời gian theo timezone của user

#### Model Patches
```ruby
# Project Patch
module RedmineReminder::ProjectPatch
  # Extends Project model with reminders association
  has_many :reminders, dependent: :destroy
end

# Issue Patch  
module RedmineReminder::IssuePatch
  # Extends Issue model with reminders association
  has_many :reminders, dependent: :nullify
end
```

### 2. Controllers Layer

#### RemindersController
**Trách nhiệm:**
- CRUD operations cho reminders
- Project-based authorization
- Issue search API (autocomplete)
- Timezone handling trong form processing

**Key Actions:**
- `index`: List reminders cho project
- `new/create`: Tạo reminder mới với timezone conversion
- `edit/update`: Cập nhật reminder
- `destroy`: Xóa reminder
- `search_issues`: API endpoint cho issue autocomplete

**Authorization Strategy:**
```ruby
before_action :find_project, :authorize
# Permissions:
# - :view_reminders -> index, show, search_issues
# - :manage_reminders -> new, create, edit, update, destroy
```

### 3. Services Layer

#### ReminderService
**Trách nhiệm:**
- Logic gửi nhắc nhở đến external services
- Message formatting cho Google Chat/Slack
- Error handling và retry logic
- Webhook management

**Core Functions:**
- Message construction với rich formatting
- HTTP client integration
- Project-specific webhook URL resolution
- Logging và monitoring

#### Listener (Hook System)
**Trách nhiệm:**
- Listen cho Redmine events
- Trigger notifications based on issue events
- Integration với Redmine notification system

### 4. Background Jobs Architecture

#### Rake Task: `redmine_reminder:send_reminders`
**Workflow:**
```
1. Query active reminders for current time
2. Filter by timezone và should_send_today? logic
3. For each qualifying reminder:
   a. Build message content
   b. Resolve webhook URL from project custom fields
   c. Send via ReminderService
   d. Handle errors và logging
   e. Update next_send_date for recurring reminders
```

**Cron Integration:**
```bash
# Chạy mỗi phút để check reminders
* * * * * cd /path/to/redmine && bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production
```

### 5. Frontend Architecture

#### View Layer Structure
```
app/views/reminders/
├── index.html.erb          # List reminders
├── show.html.erb           # View single reminder
├── new.html.erb            # Create form
├── edit.html.erb           # Edit form
└── _form.html.erb          # Shared form partial
```

#### JavaScript Components
- **Issue Autocomplete**: Select2-based search cho issue linking
- **Recurring Type Toggle**: Dynamic form fields based on recurring type
- **Date/Time Pickers**: User-friendly datetime input với timezone awareness
- **Form Validation**: Client-side validation cho recurring patterns

### 6. Integration Layer

#### Webhook Architecture
```
Project Custom Fields (configured per project):
├── google_chat_webhook     # Google Chat incoming webhook URL
├── slack_url              # Slack webhook URL (optional)
└── slack_channel          # Slack channel (optional)

Message Flow:
Reminder → ReminderService → HTTP Client → External Service Webhook
```

#### Message Formatting
**Google Chat Format:**
```json
{
  "text": "formatted message with *bold* _italic_ <link|text> <users/all>",
  "cards": [...] // Rich card format cho complex messages
}
```

**Slack Format:**
```json
{
  "text": "formatted message",
  "channel": "#general",
  "username": "redmine",
  "icon_url": "..."
}
```

### 7. Database Schema

#### Reminders Table
```sql
CREATE TABLE reminders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  project_id INT NOT NULL,
  created_by_id INT NOT NULL,
  issue_id INT NULL,
  content TEXT NOT NULL,
  send_date DATE NOT NULL,
  send_time TIME NOT NULL,  -- Stored in UTC
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_type VARCHAR(20) NULL,  -- 'daily', 'weekdays', 'weekly', 'custom'
  custom_days VARCHAR(20) NULL,     -- CSV: "1,3,5" (Mon,Wed,Fri)
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (created_by_id) REFERENCES users(id),
  FOREIGN KEY (issue_id) REFERENCES issues(id)
);
```

### 8. Configuration Architecture

#### Plugin Settings (init.rb)
```ruby
settings default: {
  'callback_url' => 'http://slack.com/callback/',
  'channel' => nil,
  'icon' => 'https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png',
  'username' => 'redmine',
  'display_watchers' => 'no',
  'google_chat_webhook_url' => ''
}
```

#### Project Module Configuration
```ruby
project_module :reminders do
  permission :view_reminders, { :reminders => [:index, :show, :search_issues] }
  permission :manage_reminders, { :reminders => [:new, :create, :edit, :update, :destroy] }
end
```

## Design Patterns

### 1. Repository Pattern
- Models chỉ chứa business logic
- Data access logic được encapsulate trong models
- Services layer cho complex business operations

### 2. Strategy Pattern  
- Different recurring types implement different calculation strategies
- Webhook sending strategies cho different platforms

### 3. Observer Pattern
- Hook system để listen cho Redmine events
- Listener pattern cho notification triggers

### 4. Factory Pattern
- Message formatting factory cho different platforms
- Timezone resolver factory

## Performance Considerations

### 1. Database Optimization
- Index trên (project_id, send_date, send_time, active)
- Efficient queries với proper joins
- Pagination cho large reminder lists

### 2. Background Job Optimization
- Batch processing cho multiple reminders
- Connection pooling cho HTTP requests
- Retry mechanism với exponential backoff

### 3. Memory Management
- Lazy loading cho associations
- Proper cleanup trong rake tasks
- Efficient date/time calculations

## Security Architecture

### 1. Authorization
- Project-based permissions
- User-based access control
- Proper parameter filtering

### 2. Data Protection
- Webhook URL validation
- XSS protection trong message content
- CSRF protection cho forms

### 3. External Integration Security
- HTTPS-only webhooks
- Webhook URL validation
- Rate limiting cho external calls 
