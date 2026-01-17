# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
Deadline.destroy_all
Enrollment.destroy_all
Session.destroy_all
User.destroy_all

# Create test user
user = User.create!(
  email_address: "student@example.com",
  password: "password123"
)
puts "Created user: #{user.email_address}"

# Sample deadlines for Keio Tsushin
user.deadlines.create!([
  {
    course_name: "Philosophy of Science",
    deadline_date: Date.today + 5.days,
    deadline_type: "report",
    description: "Submit first report on scientific methodology"
  },
  {
    course_name: "Japanese Literature",
    deadline_date: Date.today + 12.days,
    deadline_type: "report",
    description: "Analysis of modern Japanese novels"
  },
  {
    course_name: "Constitutional Law",
    deadline_date: Date.today + 20.days,
    deadline_type: "exam",
    description: "Midterm examination"
  },
  {
    course_name: "Economics 101",
    deadline_date: Date.today + 30.days,
    deadline_type: "exam",
    description: "Final exam covering all chapters"
  },
  {
    course_name: "Statistics",
    deadline_date: Date.today - 3.days,
    deadline_type: "report",
    description: "Past deadline - Statistical analysis assignment"
  }
])
puts "Created #{Deadline.count} sample deadlines"

# Sample enrollments
seasons = Season.upcoming(4).map(&:key)
if seasons.any? && Course.all.any?
  user.enrollments.create!([
    { course_key: "philosophy", season_key: seasons[0], status: "planned" },
    { course_key: "logic", season_key: seasons[0], status: "report_submitted" },
    { course_key: "english_i", season_key: seasons[1], status: "planned" },
    { course_key: "economics", season_key: seasons[1], status: "exam_applied" },
    { course_key: "constitutional_law", season_key: seasons[2], status: "completed" }
  ])
  puts "Created #{Enrollment.count} sample enrollments"
end
