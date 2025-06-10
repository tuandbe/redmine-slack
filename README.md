# Reminder plugin for Redmine (Slack & Google Chat)

This plugin posts updates to issues and wiki pages in your Redmine installation to a Slack channel and/or a Google Chat space. This is a fork of the original `redmine-slack` plugin, extended to add Google Chat support.

Improvements are welcome! Just send a pull request.

## Screenshot

![screenshot](https://raw.github.com/sciyoshi/redmine-slack/gh-pages/screenshot.png)
*(Note: Screenshot from original Slack-only version)*

## Installation

1.  From your Redmine plugins directory, clone this repository as `redmine_reminder`:

    ```
    git clone <your-repository-url> redmine_reminder
    ```

2.  You will also need the `httpclient` dependency, which can be installed by running `bundle install` from the Redmine root directory.

3.  Restart Redmine. You should see the plugin show up in `Administration > Plugins` as "Redmine Reminder". Click `Configure` to set it up.

## Configuration

You can configure notifications globally and then override them on a per-project basis.

### Global Configuration

Go to `Administration > Plugins > Redmine Reminder > Configure`.

*   **Slack:**
    *   `Slack URL`: Your main Incoming WebHook URL from Slack.
    *   `Slack Channel`: The default channel to post to (e.g., `#general`).
*   **Google Chat:**
    *   `Google Chat Webhook URL`: Your main Incoming WebHook URL from your Google Chat space.

### Per-Project Configuration

You can route messages to different channels or spaces for each project. To do this, create Project Custom Fields (`Administration > Custom fields > New custom field > Project`).

*   **For Slack:**
    *   Create a custom field named `Slack Channel`. For a project, you can enter a different channel name (e.g., `#project-alpha`). To disable Slack notifications for a project, set this field's value to `-`.
    *   Create a custom field named `Slack URL` to use a different Slack workspace for a specific project.
*   **For Google Chat:**
    *   Create a custom field named `Google Chat Webhook`. For a project, you can enter a different space's webhook URL here.

If no custom field is set for a project, the plugin will check its parent project, and if not found, it will use the global settings.

For more information on Redmine plugins, see http://www.redmine.org/projects/redmine/wiki/Plugins.
