# frozen_string_literal: true

# An enrollment status as an icon plus its name:
# `render Components::StatusBadge.new(enrollment.status)`.
class Components::StatusBadge < Components::Base
  COLORS = {
    "planned" => "bg-gray-100 text-gray-600",
    "report_submitted" => "bg-primary-50 text-primary-700",
    "exam_applied" => "bg-accent-100 text-primary-900",
    "completed" => "bg-success-50 text-success-700"
  }.freeze

  SIZES = {
    sm: [ "gap-1 px-1.5 py-0.5 rounded text-xs", "size-3 shrink-0" ],
    md: [ "gap-1.5 px-3 py-1 rounded-full text-sm font-medium", "size-4 shrink-0" ]
  }.freeze

  def initialize(status, size: :sm)
    @status = status
    @size = size
  end

  def view_template
    box, icon = SIZES.fetch(@size)

    span(class: "inline-flex items-center #{box} #{COLORS[@status]}") do
      render Components::Icon.new(@status, class: icon) if Components::Icon::PATHS.key?(@status.to_s.to_sym)
      plain t("shared.statuses.#{@status}")
    end
  end
end
