class ApplicationController < ActionController::Base
    include SessionsHelper    
    
    # 各コントローラーにおいてログインすることを求めるメソッド
    def logged_in_user
        unless logged_in?
            flash[:danger] = "Please log in"
            redirect_to root_path, status: :see_other
        end
    end
end
