class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :deadlines, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
