class UsersController < ApplicationController
  before_action :logged_in_user, only: [:show, :edit, :update, :destroy]

  # ユーザー情報の表示(Settings)
  def show
    # 仮。後々ログイン中のユーザーのものに置き換える。
    #@user = User.first
    @user = current_user
    @edit_mode = params[:edit].present?
  end

  # ユーザーの登録/表示(Signup)
  def new
    @user = User.new
  end

  # ユーザーの作成
  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to settings_path
    else
      @edit_mode = true
      render "show", status: :unprocessable_entity
    end
  end

  def destroy
    @user = current_user
    @user.destroy
    redirect_to root_path, status: :see_other
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end

