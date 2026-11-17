# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
Enrollment.destroy_all
Session.destroy_all
User.destroy_all

# Create test user
user = User.create!(
  email_address: "student@example.com",
  password: "password123"
)
puts "Created user: #{user.email_address}"

# Sample enrollments (keys must exist in config/courses.yml). Fewer than three
# upcoming seasons may be left in config/seasons.yml, so wrap around.
seasons = Season.upcoming(4).map(&:key)
if seasons.any? && Course.all.any?
  first, second, third = seasons.cycle.first(3)
  user.enrollments.create!([
    { course_key: "phil101", season_key: first, status: "planned" },
    { course_key: "logic101", season_key: first, status: "report_submitted" },
    { course_key: "eng101", season_key: second, status: "planned" },
    { course_key: "econ101", season_key: second, status: "exam_applied" },
    { course_key: "law101", season_key: third, status: "completed" }
  ])
  puts "Created #{Enrollment.count} sample enrollments"
end

# Seed documents (server mode only)
if ENV["DOCUMENT_STORAGE"] == "server"
  seed_docs_dir = Rails.root.join("db/seed_documents")

  if seed_docs_dir.exist?
    document_keys = %w[syllabus handbook reports_humanities reports_social reports_natural reports_foreign_lang reports_economics]

    seed_docs_dir.glob("*.pdf").each do |pdf_path|
      key = pdf_path.basename(".pdf").to_s
      next unless key.in?(document_keys)

      # Skip if already attached with this key
      existing = user.documents.blobs.find_by("active_storage_blobs.metadata LIKE ?", "%\"key\":\"#{key}\"%")
      next if existing

      user.documents.attach(
        io: File.open(pdf_path),
        filename: pdf_path.basename.to_s,
        content_type: "application/pdf",
        metadata: { key: key }
      )
      puts "Attached seed document: #{key}"
    end
  end
end
