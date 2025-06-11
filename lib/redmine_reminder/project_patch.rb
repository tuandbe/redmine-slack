module RedmineReminder
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_many :reminders, dependent: :destroy
    end
  end
end 
