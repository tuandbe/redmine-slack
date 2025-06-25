# Tổng quan dự án - Plugin Redmine Reminder

## Giới thiệu
Plugin Redmine Reminder là một giải pháp tích hợp mạnh mẽ giúp tự động hóa việc gửi nhắc nhở và thông báo cho các dự án Redmine. Plugin được phát triển dựa trên plugin `redmine-slack` gốc và được mở rộng để hỗ trợ Google Chat cùng với hệ thống quản lý nhắc nhở chuyên dụng.

## Mục tiêu chính
- **Tự động hóa nhắc nhở**: Tạo và quản lý các nhắc nhở tự động cho dự án
- **Đa nền tảng**: Hỗ trợ gửi thông báo qua Google Chat và Slack
- **Linh hoạt**: Hỗ trợ nhắc nhở một lần và định kỳ (hàng ngày, theo ngày làm việc, hàng tuần, tùy chỉnh)
- **Tích hợp sâu**: Liên kết với các issue cụ thể trong Redmine
- **Đa ngôn ngữ**: Hỗ trợ tiếng Anh, tiếng Việt, tiếng Nhật

## Tính năng chính

### 1. Quản lý nhắc nhở
- Tạo nhắc nhở cho dự án cụ thể
- Lên lịch nhắc nhở theo ngày và giờ
- Thiết lập nhắc nhở định kỳ với nhiều tùy chọn:
  - Hàng ngày (daily)
  - Ngày làm việc (weekdays - Thứ 2 đến Thứ 6)
  - Hàng tuần (weekly)
  - Tùy chỉnh theo ngày trong tuần

### 2. Tích hợp với Issue
- Liên kết nhắc nhở với issue cụ thể
- Tìm kiếm và chọn issue bằng autocomplete
- Hiển thị thông tin issue trong nhắc nhở

### 3. Gửi thông báo đa nền tảng
- **Google Chat**: Sử dụng webhook để gửi thông báo
- **Slack**: Hỗ trợ gửi qua Slack API
- Hỗ trợ định dạng tin nhắn rich text (bold, italic, link, mention)

### 4. Quản lý timezone
- Tự động detect timezone của user
- Ưu tiên: User preference → Redmine default → Asia/Ho_Chi_Minh
- Xử lý chính xác thời gian gửi nhắc nhở

## Kiến trúc kỹ thuật

### Models
- **Reminder**: Model chính chứa thông tin nhắc nhở
  - Thuộc về Project và User
  - Có thể liên kết với Issue
  - Hỗ trợ recurring logic

### Controllers
- **RemindersController**: Quản lý CRUD operations cho reminders
  - Authorization theo project
  - Search API cho issues
  - Timezone handling

### Services
- **ReminderService**: Logic gửi nhắc nhở
- **Listener**: Hook vào Redmine events
- **Patches**: Mở rộng chức năng của Project và Issue models

### Infrastructure
- **Rake tasks**: Scheduled job để gửi nhắc nhở
- **Cron integration**: Chạy mỗi phút để check nhắc nhở đến hạn
- **Webhook support**: Tích hợp với external services

## Phạm vi sử dụng

### Target Users
- **Project Managers**: Quản lý timeline và deadline
- **Team Leaders**: Nhắc nhở team về tasks quan trọng
- **Developers**: Reminder về code review, testing
- **Stakeholders**: Thông báo về project milestones

### Use Cases
- Daily standup reminders
- Sprint planning notifications
- Deadline alerts
- Meeting reminders
- Code review notifications
- Release announcements

## Giá trị kinh doanh
- **Tăng productivity**: Tự động hóa việc nhắc nhở manual
- **Giảm miss deadlines**: Systematic reminder system
- **Tăng transparency**: Thông báo realtime cho team
- **Flexibility**: Customize theo nhu cầu từng project
- **Cost effective**: Open source solution

## Technology Stack
- **Backend**: Ruby on Rails (tương thích với Redmine 5.x)
- **Database**: MySQL/PostgreSQL (theo Redmine config)
- **Frontend**: ERB templates với JavaScript enhancement
- **Integration**: Webhook-based với Google Chat/Slack
- **Scheduling**: Cron jobs với Rake tasks
- **Localization**: I18n support cho 3 ngôn ngữ

## Plugin Dependencies
- `httpclient`: Để gửi HTTP requests đến webhooks
- Redmine core version >= 0.8.0 (khuyến nghị 5.x)

## Roadmap tương lai
- [ ] Microsoft Teams integration
- [ ] Discord support
- [ ] Email notifications
- [ ] Template system cho messages
- [ ] Dashboard analytics
- [ ] Mobile app notifications
- [ ] AI-powered smart reminders 
