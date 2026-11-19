class PagesController < ApplicationController
  allow_unauthenticated_access

  # Visitors get the landing page; signed-in users get their overview.
  def home
    return render(Views::Pages::Home.new) unless authenticated?

    enrollments = Current.user.enrollments.to_a
    render Views::Pages::Overview.new(
      user: Current.user,
      steps: enrollments.filter_map(&:next_step).sort_by(&:date),
      credit_stats: Current.user.enrollments.credit_stats,
      any_enrollments: enrollments.any?
    )
  end

  def about
    render Views::Pages::About.new
  end

  def documents
    render Views::Pages::Documents.new
  end
end
