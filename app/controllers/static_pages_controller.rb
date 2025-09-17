class StaticPagesController < ApplicationController
    before_action :logged_in_user,  only: [:home, :help]
  def home
    # 表示すべきフェーズ判定(sprout/leaves/tree)を後々設定！

  end

  def help
  end
end
