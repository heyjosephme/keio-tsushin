# The graduation thesis (8 credits) isn't a catalog course, so it's recorded on the profile.
class AddThesisCompletedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :thesis_completed, :boolean, default: false, null: false
  end
end
