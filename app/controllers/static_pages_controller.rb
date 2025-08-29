class StaticPagesController < ApplicationController
    before_action :logged_in_user,  only: [:home, :help]
  def home
  end

  def help
  end
end
