# frozen_string_literal: true

# A course's field (分野) as a neutral chip with a coloured dot:
# `render Components::FieldTag.new(course)`.
#
# The field colours are for telling fields apart only. They are kept to a dot or a
# thin stripe so they can't be confused with the status colours (success, warning,
# danger). Use DOTS and STRIPES wherever a field needs a colour.
class Components::FieldTag < Components::Base
  DOTS = {
    "humanities" => "bg-rose-400",
    "social" => "bg-teal-500",
    "natural" => "bg-lime-600",
    "foreign_language" => "bg-sky-500",
    "economics" => "bg-primary-700"
  }.freeze

  STRIPES = {
    "humanities" => "border-l-rose-400",
    "social" => "border-l-teal-500",
    "natural" => "border-l-lime-600",
    "foreign_language" => "border-l-sky-500",
    "economics" => "border-l-primary-700"
  }.freeze

  SIZES = {
    sm: "px-2 py-0.5 rounded text-xs",
    md: "px-3 py-1 rounded-full text-sm"
  }.freeze

  def initialize(course, size: :sm)
    @course = course
    @size = size
  end

  def view_template
    span(class: "inline-flex items-center gap-1.5 font-medium bg-gray-100 text-gray-700 #{SIZES.fetch(@size)}") do
      span(class: "size-2 rounded-full #{DOTS[@course.field] || "bg-gray-400"}", aria_hidden: "true")
      plain @course.field_label
    end
  end
end
