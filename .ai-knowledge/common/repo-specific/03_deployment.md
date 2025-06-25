# Hướng dẫn triển khai - Plugin Redmine Reminder

## Tổng quan triển khai

Plugin Redmine Reminder được thiết kế để triển khai trên môi trường production Redmine 5.x với Ruby 3.0+ và Rails 6.1+. Hướng dẫn này bao gồm các bước cài đặt, cấu hình, và vận hành plugin trong môi trường thực tế.

## Yêu cầu hệ thống

### Environment Requirements
- **Redmine**: Version 5.0+ (được test trên 5.0.6.stable)
- **Ruby**: Version 3.0+ (khuyến nghị 3.0.6)
- **Rails**: Version 6.1+ (6.1.7.6)
- **Database**: MySQL 5.7+ hoặc PostgreSQL 12+
- **Web Server**: Nginx + Passenger/Puma
- **Operating System**: Linux (Ubuntu 20.04+, CentOS 8+)

### Ruby Gems Dependencies
```ruby
# Từ plugin Gemfile
gem 'httpclient', '~> 2.8'

# Dependencies từ Redmine core đã có sẵn:
# - rails
# - activerecord
# - actionpack
# - activesupport
```

## Quá trình cài đặt

### 1. Clone Plugin từ Repository

```bash
# Chuyển đến thư mục plugins của Redmine
cd /path/to/redmine/plugins

# Clone plugin
git clone <repository-url> redmine_reminder

# Hoặc download và extract nếu có archive
```

### 2. Cài đặt Dependencies

```bash
# Chuyển về thư mục root của Redmine
cd /path/to/redmine

# Install plugin gems
bundle install --without development test

# Hoặc chỉ install cho production
bundle install --deployment --without development test
```

### 3. Chạy Database Migration

```bash
# Migration cho plugin
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# Hoặc với Rails 6+
bundle exec bin/rails redmine:plugins:migrate RAILS_ENV=production

# Verify migration thành công
bundle exec bin/rails runner "puts Reminder.count" RAILS_ENV=production
```

### 4. Restart Redmine Application

```bash
# Với Passenger
touch tmp/restart.txt

# Với Puma
sudo systemctl restart redmine-puma

# Với systemd service
sudo systemctl restart redmine
```

## Cấu hình hệ thống

### 1. Cấu hình Custom Fields

Plugin yêu cầu tạo Project Custom Fields để lưu trữ webhook URLs:

**Bước 1:** Đăng nhập Redmine với quyền admin
**Bước 2:** Vào `Administration > Custom fields`
**Bước 3:** Click `New custom field` → chọn `Projects`
**Bước 4:** Tạo fields sau:

```
Field 1:
- Name: Google Chat Webhook
- Format: Long text
- For all projects: ✓ Checked

Field 2 (Optional - cho Slack):
- Name: Slack URL  
- Format: Long text
- For all projects: ✓ Checked

Field 3 (Optional - cho Slack):
- Name: Slack Channel
- Format: Text (255)
- For all projects: ✓ Checked
```

### 2. Cấu hình Project Settings

Cho mỗi project muốn sử dụng reminders:

**Bước 1:** Vào project → `Settings` tab
**Bước 2:** Scroll xuống `Custom fields` section
**Bước 3:** Điền Google Chat Webhook URL
**Bước 4:** Vào `Modules` tab → Enable `Reminders` module

### 3. Cấu hình Permissions

**Bước 1:** Vào `Administration > Roles and permissions`
**Bước 2:** Cho mỗi role cần access:
- `View reminders`: Xem danh sách và chi tiết reminders
- `Manage reminders`: Tạo, sửa, xóa reminders

## Cấu hình Cron Jobs

### 1. Setup Cron Job cho Reminder Sending

**Tạo script wrapper (khuyến nghị):**

```bash
# Tạo file /path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh
cat > /path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh << 'EOF'
#!/bin/bash
REDMINE_ROOT="/path/to/redmine"
RAILS_ENV="production"
LOG_DIR="$REDMINE_ROOT/log"

# Create daily log file
LOGFILE="$LOG_DIR/cron-$(date +%Y%m%d).log"

# Change to Redmine directory and run task
cd "$REDMINE_ROOT"

# Source user profile to ensure bundle is in PATH
source ~/.profile

# Run the reminder task
echo "$(date): Starting reminder task" >> "$LOGFILE"
bundle exec rake redmine_reminder:send_reminders RAILS_ENV="$RAILS_ENV" >> "$LOGFILE" 2>&1
echo "$(date): Finished reminder task" >> "$LOGFILE"

# Optional: Cleanup old log files (keep last 30 days)
find "$LOG_DIR" -name "cron-*.log" -mtime +30 -delete
EOF

# Làm cho script executable
chmod +x /path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh
```

**Cấu hình crontab:**

```bash
# Edit crontab
crontab -e

# Thêm dòng sau để chạy mỗi phút
* * * * * /path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh

# Hoặc run trực tiếp (không khuyến nghị):
* * * * * /bin/bash -l -c 'cd /path/to/redmine && bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production >> log/cron-$(date +\%Y\%m\%d).log 2>&1'
```

### 2. Monitoring Cron Jobs

**Kiểm tra cron đang chạy:**
```bash
# Xem cron jobs của user hiện tại
crontab -l

# Monitor cron log
tail -f /var/log/cron

# Monitor plugin log
tail -f /path/to/redmine/log/cron-$(date +%Y%m%d).log
```

**Test cron job manually:**
```bash
# Chạy script test
/path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh

# Hoặc chạy rake task trực tiếp
cd /path/to/redmine
bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production
```

## Cấu hình Webhook Services

### 1. Google Chat Setup

**Bước 1: Tạo Incoming Webhook**
1. Mở Google Chat trong workspace
2. Vào space muốn nhận notifications
3. Click vào tên space → `Manage webhooks`
4. Click `Add webhook`
5. Đặt tên (ví dụ: "Redmine Reminders")
6. Copy webhook URL

**Bước 2: Cấu hình trong Redmine**
1. Vào project settings
2. Paste webhook URL vào `Google Chat Webhook` field

**Bước 3: Test Integration**
```bash
cd /path/to/redmine
bundle exec rake "redmine_reminder:test_webhook[PROJECT_IDENTIFIER]" RAILS_ENV=production
```

### 2. Slack Setup (Optional)

**Bước 1: Tạo Slack App**
1. Vào https://api.slack.com/apps
2. Click `Create New App`
3. Enable `Incoming Webhooks`
4. Copy webhook URL

**Bước 2: Cấu hình trong Redmine**
1. Paste webhook URL vào `Slack URL` field
2. Điền channel name vào `Slack Channel` field (ví dụ: #general)

## Monitoring và Troubleshooting

### 1. Log Files Locations

```bash
# Redmine main log
/path/to/redmine/log/production.log

# Cron job logs (daily files)
/path/to/redmine/log/cron-YYYYMMDD.log

# System cron log
/var/log/cron

# Nginx access/error logs
/var/log/nginx/access.log
/var/log/nginx/error.log
```

### 2. Common Issues và Solutions

**Issue: Cron job không chạy**
```bash
# Check cron service
sudo systemctl status cron

# Check user crontab
crontab -l

# Check cron permissions
ls -la /usr/bin/crontab

# Test script manually
/path/to/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh
```

**Issue: Bundle command not found trong cron**
```bash
# Solution: Use full path hoặc source profile
/bin/bash -l -c 'command'

# Hoặc specify full path
/home/user/.rbenv/shims/bundle exec rake ...
```

**Issue: Database connection errors**
```bash
# Check database config
cat /path/to/redmine/config/database.yml

# Check database connectivity
bundle exec bin/rails runner "puts ActiveRecord::Base.connection.active?" RAILS_ENV=production

# Check database permissions
mysql -u redmine_user -p redmine_db
```

**Issue: Webhook không gửi được**
```bash
# Test webhook manually
curl -X POST -H "Content-Type: application/json" \
  -d '{"text": "Test message"}' \
  "YOUR_WEBHOOK_URL"

# Check plugin logs
grep -i webhook /path/to/redmine/log/production.log

# Test từ Redmine
bundle exec rake "redmine_reminder:test_webhook[PROJECT_ID]" RAILS_ENV=production
```

### 3. Performance Monitoring

**Database query monitoring:**
```bash
# Check slow queries
tail -f /var/log/mysql/slow.log

# Monitor reminder table
mysql -u root -p
> SELECT COUNT(*) FROM reminders WHERE active = 1;
> EXPLAIN SELECT * FROM reminders WHERE send_date = CURDATE() AND send_time = CURTIME();
```

**Memory và CPU monitoring:**
```bash
# Monitor during cron execution
htop

# Check memory usage
free -h

# Monitor disk space
df -h
```

## Backup và Recovery

### 1. Database Backup

```bash
# Backup reminder data
mysqldump -u root -p redmine_db reminders > reminders_backup_$(date +%Y%m%d).sql

# Full Redmine backup
mysqldump -u root -p redmine_db > redmine_full_backup_$(date +%Y%m%d).sql
```

### 2. Plugin Files Backup

```bash
# Backup plugin directory
tar -czf redmine_reminder_backup_$(date +%Y%m%d).tar.gz \
  /path/to/redmine/plugins/redmine_reminder/

# Backup custom field configurations
mysqldump -u root -p redmine_db custom_fields custom_values > custom_fields_backup.sql
```

### 3. Recovery Process

```bash
# Restore database
mysql -u root -p redmine_db < reminders_backup_YYYYMMDD.sql

# Re-run migrations nếu cần
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# Restart services
sudo systemctl restart nginx redmine
```

## Security Considerations

### 1. Webhook URL Security
- Chỉ sử dụng HTTPS webhooks
- Không log webhook URLs trong plain text
- Rotate webhook URLs định kỳ

### 2. Cron Job Security
- Chạy với user privileges tối thiểu
- Secure log file permissions (640)
- Monitor cron job execution

### 3. Database Security
- Regular backup encrypted storage
- Secure database credentials
- Monitor database access logs

## Scaling và Optimization

### 1. High Load Optimization
- Database indexing cho reminder queries
- Connection pooling cho webhooks
- Batch processing cho multiple reminders

### 2. Multi-server Deployment
- Chạy cron job trên single server để tránh duplicate
- Shared database cho multiple Redmine instances
- Load balancer configuration

### 3. Monitoring Tools Integration
- New Relic/DataDog cho application monitoring
- Prometheus metrics cho webhook success/failure rates
- Alerting cho cron job failures 
