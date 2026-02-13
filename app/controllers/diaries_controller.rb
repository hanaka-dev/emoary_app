class DiariesController < ApplicationController
    before_action :logged_in_user, only: [:new, :confirm, :create]
    
    def new
        @diary = current_user.diaries.new
    end

    # 一旦入力。まだ保存しない（確認画面用）
    def confirm
        @diary = current_user.diaries.new(diary_params)
        render :confirm
    end

    # 保存する
    def create
        @diary = current_user.diaries.new(diary_params)

        # —— ここから自動セット (ユーザ入力なし)—— 
        Time.use_zone(current_user.timezone.presence || "Asia/Tokyo") do
        journal_date = Time.zone.today  # いまはJST基準。将来は国/タイムゾーンで切替予定

        # 今日（journal_date）の既存レコードを取る
        todays = current_user.diaries.where(created_at: journal_date.all_day)

        # day_no: そのユーザーにとって「何日目の記録か」
        # 既に今日の記録があれば同じ day_no を使い回し。無ければ最大+1
        if todays.exists?
            @diary.day_no = todays.first.day_no
        else
            last_day_no = current_user.diaries.maximum(:day_no) || 0
            @diary.day_no = last_day_no + 1
        end

        # seq_no: 今日の中で何枚目か
        @diary.seq_no = (todays.count + 1)

        # tree_index: 35枚/本で割った商から求める
        @diary.tree_index = ((@diary.day_no - 1) / 35)

        # flag: 代表フラグ。初回の1枚だけ自動でtrue。他はfalse。
        @diary.flag = todays.empty? # その日最初なら true
        end
        # —— 自動セットここまで —— 
        if @diary.save
            flash[:success] = "Your new leaf has sprouted!"
            redirect_to root_path
        else
            flash[:error] = "Failure..."
            render "static_pages/home", status: :unprocessable_entity
        end
    end


    private
        def diary_params
            params.require(:diary).permit(:emo_1, :emo_2, :emo_3, :rate_1, :rate_2, :rate_3, :content)
        end
end
