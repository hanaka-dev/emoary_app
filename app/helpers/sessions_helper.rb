module SessionsHelper

    # 渡されたユーザーでログインする
    def log_in(user)
        session[:user_id] = user.id
    end

    # 現在ログイン中のユーザーを返す
    def current_user
        if session[:user_id]
            @current_user ||= User.find_by(id: session[:user_id])
        end
    end

    # ユーザーがログインしていればtrue,そうでないならfalse
    def logged_in?
        !current_user.nil?
    end

    # 現在のユーザーをログアウトする
    def log_out
        reset_session
        @current_user = nil
    end
end
