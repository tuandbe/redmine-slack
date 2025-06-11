class CreateReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :reminders do |t|
      t.integer :project_id, null: false
      t.integer :created_by_id, null: false
      t.integer :issue_id, null: true
      t.text :content
      t.time :send_time
      t.date :send_date
      t.boolean :is_recurring, default: false
      t.string :recurring_type # 'daily', 'weekdays', 'weekly', 'custom'
      t.string :custom_days # For custom recurring, store as comma-separated values: '1,3,5' for Mon,Wed,Fri
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :reminders, :project_id
    add_index :reminders, :send_date
    add_index :reminders, :active
    add_index :reminders, :created_by_id
    add_index :reminders, :issue_id
  end
end 
