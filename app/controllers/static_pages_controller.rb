class StaticPagesController < ApplicationController
    before_action :logged_in_user,  only: [:home, :help]
  def home
    # ホームの木は「その日の代表」だけ（flag=true）。成長サイクルも代表エントリの件数で数える
    scope = current_user.diaries.where(flag: true).order(:created_at, :id)
    total = scope.count
    visible = HomeGrowthHelper.visible_diary_count_for_total(total)
    @home_diaries =
      if visible.zero?
        []
      else
        scope.offset(total - visible).limit(visible).to_a
      end
  end

  def help
  end
end
