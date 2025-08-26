class UsersController < ApplicationController

  # ユーザー情報の表示(Settings)
  def show
    @user = User.find(params[:id])
  end

  # ユーザーの登録(Signup)
  def new
    @user = User.new
  end
end
