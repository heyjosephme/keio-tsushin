class Course < ApplicationRecord
  STATUSES = %w[planned report_submitted exam_applied completed].freeze

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :credits, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :for_season, ->(season_key) { where(season_key: season_key) }
  scope :planned, -> { where(status: "planned") }
  scope :completed, -> { where(status: "completed") }

  def season
    Season.find(season_key) if season_key.present?
  end

  def move_to_season!(new_season_key)
    update!(season_key: new_season_key)
  end

  def status_label
    status.to_s.titleize.gsub("_", " ")
  end
end
