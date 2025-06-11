#!/bin/bash

# Cron script to run reminders every minute
# Add this to your crontab:
# * * * * * /path/to/redmine/plugins/redmine_reminder/bin/cron_reminder.sh

# Change to Redmine root directory
cd "$(dirname "$0")/../../../"

# Set environment
export RAILS_ENV=production

# Run the reminder task
bundle exec rake redmine_reminder:send_reminders

# Log the execution
echo "$(date): Reminder cron executed" >> log/reminder_cron.log 
