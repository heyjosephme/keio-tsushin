# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing deadlines
Deadline.destroy_all

# Sample deadlines for Keio Tsushin
Deadline.create!([
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
