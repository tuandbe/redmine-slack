# Redmine Reminder Plugin (with Google Chat & Slack support)

This plugin enhances Redmine by adding a powerful reminder feature. It allows users to create scheduled and recurring reminders for projects, which are then sent as notifications to specified Google Chat spaces or Slack channels.

This plugin is based on the original `redmine-slack` plugin and has been extended to include robust support for Google Chat and a dedicated reminder management system.

## Features

-   Create reminders for specific projects.
-   Schedule reminders for a specific date and time.
-   Set up recurring reminders (daily, weekdays, weekly, custom days).
-   Link reminders to specific Redmine issues.
-   Send notifications to Google Chat and/or Slack.
-   Per-project notification settings.
-   Multi-language support (English, Vietnamese, Japanese).

## Installation

1.  **Clone the Plugin**
    From your Redmine `plugins` directory, clone this repository:
    ```bash
    git clone <your-repository-url> redmine_reminder
    ```

2.  **Install Dependencies**
    Ensure you have the `httpclient` gem. From your Redmine root directory, run:
    ```bash
    bundle install
    ```

3.  **Run Migrations**
    Run the database migration to create the necessary tables for the reminders:
    ```bash
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    ```

4.  **Restart Redmine**
    Restart your Redmine application server (e.g., Puma, Unicorn, Passenger) for the changes to take effect. You should see "Redmine Reminder" in `Administration > Plugins`.

## Configuration

### 1. Set up Custom Fields for Notifications

To tell the plugin where to send notifications for each project, you must create a Project Custom Field.

-   Navigate to `Administration > Custom fields`.
-   Click `New custom field` and select **Projects**.
-   Create the following field:
    -   **Name**: `Google Chat Webhook`
    -   **Format**: Long text
    -   **For all projects**: Check this box.
    *You can do the same for Slack by creating `Slack URL` and `Slack Channel` custom fields if needed.*

### 2. Configure Webhook URL in Project Settings

-   Go to a project's `Settings` tab.
-   In the "Custom fields" section, paste the **Incoming Webhook URL** for your Google Chat space into the `Google Chat Webhook` field.

### 3. Set Up Cron Job for Sending Reminders

The plugin relies on a Rake task to check for and send due reminders. You need to set up a cron job to run this task periodically (e.g., every minute).

-   Create a Rake task file if it doesn't exist, or simply use the command directly.
-   Open your crontab for editing:
    ```bash
    crontab -e
    ```
-   Add the following line, making sure to replace `/path/to/redmine` with the absolute path to your Redmine installation:
    ```bash
    * * * * * cd /path/to/redmine && bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production >> log/cron.log 2>&1
    ```
    This command runs the task every minute and logs its output to `log/cron.log`.

-   Add the following line, making sure to replace `/path/to/redmine` with the absolute path to your Redmine installation:
    
    **Option 1: Simple daily log files**
    ```bash
    * * * * * /bin/bash -l -c 'cd /opt/bitnami/redmine && bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production >> log/cron-$(date +\%Y\%m\%d).log 2>&1'
    ```
    
    **Option 2: Using wrapper script (with automatic cleanup)**
    ```bash
    * * * * * /opt/bitnami/redmine/plugins/redmine_reminder/bin/run_reminder_with_log.sh
    ```
    
    This will create daily log files like `cron-20250619.log`, `cron-20250620.log`, etc.

> **Note on cron environment:** The command is wrapped in `/bin/bash -l -c '...'` to ensure it runs in a login shell. This is crucial because cron jobs run with a minimal environment and often cannot find the `bundle` command. This wrapper loads your user's shell profile (like `.bash_profile` or `.profile`), which sets up the correct `PATH` for Ruby and Bundler.

## Usage

Once configured, a "Reminders" tab will appear in the project menu.

-   Click the tab to view, create, edit, and delete reminders.
-   When creating a reminder, you can set its content, schedule, and recurrence rules.
-   The content field supports Google Chat's formatting syntax.

### Google Chat Message Formatting

When writing a reminder's content, you can use the following syntax for formatting in Google Chat:

-   `*bold text*` for **bold**
-   `_italic text_` for _italics_
-   `~strikethrough text~` for ~strikethrough~
-   `<https://example.com|Link Text>` for hyperlinks.
-   `<users/all>` to mention everyone in the space.
-   `<users/user@example.com>` to mention a specific person.

## Rake Tasks for Maintenance

The plugin provides several Rake tasks for administrative purposes. Run them from your Redmine root directory.

-   **Send due reminders (the main task for cron):**
    ```bash
    bundle exec rake redmine_reminder:send_reminders RAILS_ENV=production
    ```

-   **Test the webhook for a specific project:**
    ```bash
    bundle exec rake "redmine_reminder:test_webhook[PROJECT_ID]" RAILS_ENV=production
    ```
    Replace `PROJECT_ID` with the actual ID or identifier of the project.

## Troubleshooting

-   **Reminders not sending?**
    1.  Check that the project has the `Google Chat Webhook` custom field correctly configured.
    2.  Ensure the reminder is marked as "Active".
    3.  Verify that your cron job is running correctly and there are no errors in `log/cron.log`.
    4.  Run the `send_reminders` task manually and check the output in `log/production.log`.

-   **Webhook Errors?**
    1.  Double-check the webhook URL.
    2.  Use the `test_webhook` task to see if Redmine can reach the URL.
    3.  Ensure the bot has permission to post in the Google Chat space.
