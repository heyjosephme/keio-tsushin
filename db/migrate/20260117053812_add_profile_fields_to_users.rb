class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :enrolled_date, :date
    add_column :users, :expected_graduation_year, :integer
    add_column :users, :credits_goal_per_year, :integer
  end
end
