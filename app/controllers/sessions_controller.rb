class SessionsController < ApplicationController
  def new
  end

  # 公開デモ（パスワード入力なし）。Remember me は付けない。
  def create_demo
    user = User.find_by(demo_account: true)
    unless user&.activated?
      flash[:danger] = "Demo account is not available."
      redirect_to root_path, status: :see_other
      return
    end
    reset_session
    forget(user)
    log_in user
    flash[:info] = "You are viewing a demo account. New leaves are cleared when you log out."
    redirect_to home_path, status: :see_other
  end

  def create
    @user = User.find_by(email: params[:session][:email].downcase)
    if @user &.authenticate(params[:session][:password])
      if @user.activated?
        # ユーザーログイン後にホームにリダイレクトする
        reset_session
        params[:session][:remember_me] == "1" ? remember(@user) : forget(@user)
        log_in @user
        redirect_to home_path
      else 
        message  = "Account not activated."
        message += "Check your email for the activation link."
        flash.now[:warning] = message
        render "new", status: :unprocessable_entity
      end
    else
      flash.now[:danger] = "Invalid email/password combination"
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url, status: :see_other
  end

end
