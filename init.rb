require 'redmine'

require File.expand_path('../lib/redmine_reminder/listener', __FILE__)

Redmine::Plugin.register :redmine_reminder do
	name 'Redmine Reminder'
	author 'Samuel Cormier-Iijima & HAPO'
	url 'https://github.com/sciyoshi/redmine-slack'
	author_url 'http://www.sciyoshi.com'
	description 'Slack and Google Chat integration'
	version '0.3.1'

	requires_redmine :version_or_higher => '0.8.0'

	settings \
		:default => {
			'callback_url' => 'http://slack.com/callback/',
			'channel' => nil,
			'icon' => 'https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png',
			'username' => 'redmine',
			'display_watchers' => 'no',
			'google_chat_webhook_url' => ''
		},
		:partial => 'settings/reminder_settings'
end

if Rails.version > '6.0' && Rails.autoloaders.zeitwerk_enabled?
	Rails.application.config.after_initialize do
		unless Issue.included_modules.include? RedmineReminder::IssuePatch
			Issue.send(:include, RedmineReminder::IssuePatch)
		end
	end
else
	((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
		require_dependency 'issue'
		unless Issue.included_modules.include? RedmineReminder::IssuePatch
			Issue.send(:include, RedmineReminder::IssuePatch)
		end
	end
end
