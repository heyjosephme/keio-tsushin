class AddUserToDeadlines < ActiveRecord::Migration[8.1]
  def change
    add_reference :deadlines, :user, null: true, foreign_key: true
  end
end
