class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :season_key
      t.string :status
      t.integer :credits

      t.timestamps
    end
  end
end
