class ProfilesController < ApplicationController
  def show
    render Views::Profiles::Show.new(user: Current.user)
  end

  def edit
    render Views::Profiles::Edit.new(user: Current.user)
  end

  def update
    if Current.user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully!"
    else
      render Views::Profiles::Edit.new(user: Current.user), status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :major, :enrolled_year, :enrolled_semester, :expected_graduation_year, :credits_goal_per_year)
  end
end
