#!/bin/bash

# Get current date in YYYYMMDD format
DATE=$(date +%Y%m%d)

# Change to Redmine directory
cd /opt/bitnami/redmine

# Run the rake task and append to daily log file
bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production >> log/cron-${DATE}.log 2>&1

# Optional: Clean up old log files (keep only last 30 days)
find log/ -name "cron-*.log" -type f -mtime +30 -delete 
