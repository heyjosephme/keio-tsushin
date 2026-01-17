class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    render Views::Pages::Home.new
  end

  def about
    render Views::Pages::About.new
  end
end
