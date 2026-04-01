class SessionsController < ApplicationController
  def new
  end

  # 公開デモ（パスワード入力なし）。Remember me は付けない。
  # ビルド時に DB に繋げず demo:ensure がスキップされても、ここで一度 DemoAccountSeed を走らせて修復する。
  def create_demo
    begin
      DemoAccountSeed.ensure!(force_rebuild: false)
    rescue StandardError => e
      Rails.logger.error "[create_demo] DemoAccountSeed failed: #{e.class}: #{e.message}"
      flash[:danger] = "Demo account could not be prepared. Please try again later."
      redirect_to root_path, status: :see_other
      return
    end

    demo_email = ENV["DEMO_ACCOUNT_EMAIL"].to_s.downcase.strip.presence || "demo@emoary.app"
    user = User.find_by(demo_account: true) || User.find_by(email: demo_email)

    unless user&.activated?
      flash[:danger] = "Demo account is not available."
      redirect_to root_path, status: :see_other
      return
    end

    # 前回セッションの追加分を捨ててからログイン（ブラウザを閉じずに再デモした場合の掃除）
    user.purge_non_demo_seed_diaries!

    reset_session
    forget(user)
    log_in user
    flash[:info] = "You are viewing a demo account. New leaves are cleared when you log out."
    redirect_to home_path, status: :see_other
  end

  def create
    email = params[:session][:email].to_s.downcase.strip
    password = params[:session][:password].to_s
    @user = User.find_by(email: email)
    if @user&.authenticate(password)
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
