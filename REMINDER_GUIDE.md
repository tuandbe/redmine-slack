# Hướng dẫn sử dụng tính năng Reminder

## Giới thiệu

Tính năng Reminder cho phép tạo và quản lý các thông báo nhắc nhở tự động được gửi tới Google Chat theo lịch trình đã định.

## Yêu cầu hệ thống

1. **Custom Field cho Project**: Tạo custom field với tên `Google Chat Webhook` để lưu URL webhook của Google Chat space.
2. **Cron Job**: Cài đặt cron job để chạy reminder task mỗi phút.

## Cài đặt

### 1. Chạy migration
```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### 2. Restart Redmine
```bash
# Restart your web server (Apache, Nginx, etc.)
```

### 3. Tạo Custom Field cho Google Chat Webhook
- Vào **Administration** → **Custom Fields** → **Projects**
- Tạo custom field mới:
  - **Name**: `Google Chat Webhook`
  - **Format**: Long text
  - **Required**: No
  - **For all projects**: Yes

### 4. Cài đặt Cron Job
```bash
# Make script executable
chmod +x /path/to/redmine/plugins/redmine_reminder/bin/cron_reminder.sh

# Add to crontab (run every minute)
crontab -e
# Add this line:
* * * * * /path/to/redmine/plugins/redmine_reminder/bin/cron_reminder.sh
```

## Sử dụng

### 1. Cấu hình Google Chat Webhook cho Project
- Vào project → **Settings** → **Information**
- Trong phần Custom Fields, nhập URL webhook của Google Chat space
- URL có dạng: `https://chat.googleapis.com/v1/spaces/.../messages?key=...`

### 2. Tạo Reminder
- Vào project → **Reminder** (menu bên trái)
- Click **Tạo Reminder mới**
- Điền thông tin:
  - **Nội dung**: Hỗ trợ Markdown
  - **Ngày gửi**: Ngày bắt đầu gửi
  - **Giờ gửi**: Giờ phút cụ thể
  - **Issue liên quan**: Tùy chọn
  - **Cài đặt lặp lại**: 
    - Hàng ngày
    - Mỗi ngày làm việc (T2-T6)
    - Hàng tuần
    - Tuỳ chỉnh (chọn các ngày cụ thể)

### 3. Quản lý Reminder
- **Xem danh sách**: Tất cả reminders của project
- **Sửa**: Cập nhật thông tin reminder
- **Xóa**: Xóa reminder
- **Tạm dừng**: Bỏ tick "Kích hoạt reminder"

## Các lệnh hữu ích

### Chạy reminder thủ công
```bash
cd /path/to/redmine
bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production
```

### Xem reminders sắp tới
```bash
bundle exec rake redmine_reminder:upcoming RAILS_ENV=production
```

### Test webhook
```bash
bundle exec rake redmine_reminder:test_webhook[PROJECT_ID] RAILS_ENV=production
```

## Troubleshooting

### Reminder không được gửi
1. Kiểm tra project có custom field `Google Chat Webhook` đã được cấu hình
2. Kiểm tra reminder có trạng thái "Hoạt động"
3. Kiểm tra cron job có chạy đúng
4. Xem log: `tail -f log/production.log | grep ReminderService`

### Lỗi webhook
- Kiểm tra URL webhook có đúng định dạng
- Test webhook: `rake redmine_reminder:test_webhook[PROJECT_ID]`
- Kiểm tra quyền của bot trong Google Chat space

### Debug cron job
```bash
# Kiểm tra cron log
tail -f log/reminder_cron.log

# Chạy thủ công script
/path/to/redmine/plugins/redmine_reminder/bin/cron_reminder.sh
```

## Định dạng tin nhắn

Reminder sẽ gửi tin nhắn với format:
```
🔔 **Reminder từ dự án [Tên Project]**

[Nội dung reminder]

📋 **Issue liên quan:** [#123 Tiêu đề issue] (nếu có)

⏰ Thời gian: 25/12/2024 lúc 09:30
🔄 Lặp lại: Hàng ngày (nếu có cài đặt lặp lại)
```

## Lưu ý

- Reminder chỉ gửi cho các project có cấu hình Google Chat Webhook
- Thời gian được tính theo timezone của server
- Reminder lặp lại sẽ tự động cập nhật ngày gửi tiếp theo
- Nội dung hỗ trợ Markdown sẽ được convert sang plain text khi gửi 
