class ChangeEnrolledDateToYearAndSemester < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :enrolled_year, :integer
    add_column :users, :enrolled_semester, :string
    remove_column :users, :enrolled_date, :date
  end
end
