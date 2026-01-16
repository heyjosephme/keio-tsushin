class RenameCourseToEnrollment < ActiveRecord::Migration[8.1]
  def change
    rename_table :courses, :enrollments
    rename_column :enrollments, :name, :course_key
    remove_column :enrollments, :credits, :integer
  end
end
