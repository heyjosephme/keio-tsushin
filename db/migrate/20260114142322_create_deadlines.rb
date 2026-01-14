class CreateDeadlines < ActiveRecord::Migration[8.1]
  def change
    create_table :deadlines do |t|
      t.string :course_name
      t.date :deadline_date
      t.string :deadline_type
      t.text :description

      t.timestamps
    end
  end
end
