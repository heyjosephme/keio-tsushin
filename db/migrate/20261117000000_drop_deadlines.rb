# Deadlines are no longer per-user records: every date comes from config/seasons.yml.
class DropDeadlines < ActiveRecord::Migration[8.1]
  def change
    drop_table :deadlines do |t|
      t.string :course_name
      t.date :deadline_date
      t.string :deadline_type
      t.text :description
      t.integer :user_id
      t.timestamps
      t.index :user_id
    end
  end
end
