module ApplicationHelper
    # アイコン表示用ヘルパー
    include Heroicon::Engine.helpers

    #ページごとの完全なタイトルを返す                           #コメント行
    def full_title(page_title = "")                         #メソッド定義とオプション引数
        base_title = "Emoary"    #変数への代入
        if page_title.empty?                                #論理値テスト
            base_title                                      #暗黙の戻り値
        else
            "#{page_title} | #{base_title}"                 #文字列の式展開
        end
    end

end
