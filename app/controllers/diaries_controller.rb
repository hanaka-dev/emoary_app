class DiariesController < ApplicationController
    before_action :logged_in_user, only: [:new, :confirm, :create]
    
    def new
        @diary = params[:diary].present? ? current_user.diaries.new(diary_params) : current_user.diaries.new
    end

    # 一旦入力。まだ保存しない（確認画面用）
    def confirm
        @diary = current_user.diaries.new(diary_params)
        render :confirm
    end

    # 保存する
    def create
        @diary = current_user.diaries.new(diary_params)

        # —— 自動セット (ユーザ入力なし): ユーザーTZの暦日で day_no / seq_no / 表示用 flag ——
        zone = current_user.timezone_for_diaries
        journal_date = nil
        Time.use_zone(zone) do
          journal_date = Time.zone.today
          todays = current_user.diaries.where(created_at: journal_date.all_day)

          # day_no: その日に既に記録があれば同一。なければこれまでの最大 +1（記録した「日数」）
          if todays.exists?
            @diary.day_no = todays.order(:created_at, :id).pick(:day_no)
          else
            last_day_no = current_user.diaries.maximum(:day_no) || 0
            @diary.day_no = last_day_no + 1
          end

          # seq_no: その暦日内で何枚目か（1始まり）
          @diary.seq_no = todays.count + 1

          # 保存後に reconcile で「その日で最も早い created_at」の1件だけ true にそろえる
          @diary.flag = false
        end
        # —— 自動セットここまで ——
        if @diary.save
            Diary.reconcile_display_flags_for_user_journal_date!(current_user, journal_date, zone)
            flash[:success] = "Your new leaf has sprouted!"
            redirect_to home_path
        else
            flash[:error] = "Failure..."
            render "static_pages/home", status: :unprocessable_entity
        end
    end


    private
        # emo_1〜3 は EMOTIONS の ID（表示名は Diary#emo_name）。rate_*・content を DB に保存。
        def diary_params
            h = params.require(:diary).permit(:emo_1, :emo_2, :emo_3, :rate_1, :rate_2, :rate_3, :content).to_h
            %w[emo_2 emo_3 rate_2 rate_3].each do |key|
                h[key] = nil if h[key].blank?
            end
            h
        end
end
