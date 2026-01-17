class AddMajorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :major, :string
  end
end
