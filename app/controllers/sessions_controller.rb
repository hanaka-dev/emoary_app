class SessionsController < ApplicationController
  def new
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
