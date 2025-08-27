class UsersController < ApplicationController

  # ユーザー情報の表示(Settings)
  def show
    # 仮。後々ログイン中のユーザーのものに置き換える。
    @user = User.first
    #@user = current_user
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
      # @user.send_actibation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_paramas)
      flash[:success] = "Profile updated"
      redirect_to settings_path
    else
      @edit_mode = true
      render :show, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

end
