module SessionsHelper

    # 渡されたユーザーでログインする
    def log_in(user)
        session[:user_id] = user.id
        session[:session_token] = user.session_token
    end

    # 永続的セッションのためにユーザーをデータベースに記憶する
    def remember(user)
        # remember_token取得
        user.remember
        # cookiesに暗号化(encrypted)登録
        cookies.permanent.encrypted[:user_id] = user.id
        cookies.permanent[:remember_token] = user.remember_token

    end

    # 記憶トークンcookieに対応するユーザーを返す
    def current_user
        if (user_id = session[:user_id])
            user = User.find_by(id: user_id)
            if user && session[:session_token] == user.session_token
                @current_user = user
            end
        elsif (user_id = cookies.encrypted[:user_id])
            user = User.find_by(id: user_id)
            if user && user.authenticated?(cookies[:remember_token])
                log_in user
                @current_user = user
            end
        end
    end

    # 渡されたユーザーがカレントユーザーであればtrueを返す
    def current_user?(user)
        user && user == current_user
    end

    # ユーザーがログインしていればtrue,そうでないならfalse
    def logged_in?
        !current_user.nil?
    end

    # 永続的セッションを放棄する
    def forget(user)
        user.forget
        cookies.delete(:user_id)
        cookies.delete(:remember_token)
    end

    # 現在のユーザーをログアウトする
    def log_out
        forget(current_user)
        reset_session
        @current_user = nil
    end
end