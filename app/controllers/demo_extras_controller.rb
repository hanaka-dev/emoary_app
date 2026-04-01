# frozen_string_literal: true

# デモユーザーがタブを閉じる・別ページへ完全に離れるときに sendBeacon で呼ばれ、
# 公式22枚以外の日記を削除する。
class DemoExtrasController < ApplicationController
  before_action :logged_in_user

  def create
    unless current_user.demo_account?
      head :forbidden
      return
    end

    current_user.purge_non_demo_seed_diaries!
    head :ok
  end
end
