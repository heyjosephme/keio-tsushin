# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_17_054818) do
  create_table "deadlines", force: :cascade do |t|
    t.string "course_name"
    t.datetime "created_at", null: false
    t.date "deadline_date"
    t.string "deadline_type"
    t.text "description"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_deadlines_on_user_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.string "course_key"
    t.datetime "created_at", null: false
    t.string "season_key"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "credits_goal_per_year"
    t.string "email_address", null: false
    t.string "enrolled_semester"
    t.integer "enrolled_year"
    t.integer "expected_graduation_year"
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "deadlines", "users"
  add_foreign_key "enrollments", "users"
  add_foreign_key "sessions", "users"
end
