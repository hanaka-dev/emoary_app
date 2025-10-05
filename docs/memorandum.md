# emoary開発　備忘録
emoary開発において、今後複雑になるであろうページ名、ルーティング、モデル、コントローラーなどこんがらがりそうな要素についてはここにまとめておくこととする。また、進捗管理もここで行う。

## 進捗管理
まずRailsチュートリアルで学習したポイントで流用できそうな部分から作成する。　　　

1. **static_pagesを作成する。**

   static_pages(静的なページ)としては以下のページを指定する。いずれもGET以外のリクエストを発しない。ブランチ名:static-pages
   |ページ名|機能|
   |-|-|
   |home|ホーム画面。基本的にユーザはどの機能にアクセスするにも最初にこのページから辿っていくこととなる。|
   |help|ユーザーに本アプリの使用方法などについて解説する。各ページに配置予定。|
   
   
2. **ログイン・アカウント認証・パスワード再設定機構を作成する。**

## 報告
**2025/08/25**
    
- ひとまずRenderを用いた初期デプロイに成功
- static_pagesとしてhome,helpの２種類を作成
- helpには往復のリンクを貼った。(pencil-square,left-arrowアイコンを用いて)
- **現在、rootはstatic_pages#homeとしてあるが、後々loginに切り替える予定。**
- Userモデルと軽い制約を作成
**2025/08/26**

- Tailwindを導入　　　

   　→　Tailwindで気をつけること
      
   - 基本的に自らCSSを書かずともhtmlのclass名から呼び出すことでスタイルの適用が可能。
   - 自身で特別にCSSを記述する必要がある際には、assets/tailwind/application.cssに記述する。
   - CSSを自力で記述するにしてもお作法がCSSとは異なるようなので注意
   - フォントをインポートする際にはファイルのトップに置くこと

- Signup(new,create)作成
- TLSを用いるように変更(httpsに)
- HTTPサーバー(Puma)を本番環境で用いるように設定
- データベースとしてPostgreSQLを用いるようにpgを追加

## Gemまとめ
|名前|機能|
|-|-|
|bcrypt|パスワードのハッシュ化用|
|faker|ダミーデータ生成用|
|will_paginate|ページネーション用|
|bootstrap-will_paginate|will_paginateをBootstrap風に整える|
|bootstrap-sass|Bootstrapを使うためのGem|
|heroicon|アイコン表示用|
|pg|production環境でPostgreSQLを用いるためのGem|
## コントローラー
|コントローラー名|アクション名|機能|
|-|-|-|
|static_pages_controller.rb|home|木が表示され全ページの真ん中となるページの表示|
||help|ヘルプページ表示|
|users_controller.rb|new|新規ユーザー登録(Signup)|
||create|ユーザー作成|
||show|ユーザー情報の表示(Setting)|
|sessions_controller.rb|new|セッションの登録(login)|
||create|セッションの作成|
||destroy|セッションの削除|

## モデル
### User
|属性名,型名|内容|種別|
|-|-|-|
|id(integer)|ユーザーを特定する番号||
|name(string)|ユーザーの名前||
|email(string)|ユーザーのメアド||
|created_at(datetime)|作成日時|自動|
|updated_at(datetime)|更新日時|自動|
|password_digest(string)|ハッシュ化されたパスワード||
|password(string)|パスワード本体|仮想|
|password_confirmation(string)|再入力されたパスワード|仮想|

## テスト
|テスト名|用途|
|-|-|
|sattic_pages_controller_test.rb|静的ページのタイトル表示確認、ルートページ表示確認|
|application_helper_test.rb|動的タイトル表示ヘルパー(application_helperのfull_title)の動作確認|
|user_test.rb|ユーザー登録におけるユーザーの正当性確認|
|users_signup_test|ユーザー登録におけるcreateがうまくいくか、activationできたかを確認|

## 関数
|関数名|所属|効果範囲|説明|
|-|-|-|-|
|log_in(user)|sessions_helper.rb|application_controller.rbにincludeされているため、全コントローラ、ビューで使用可能|sessionハッシュの:user_idにユーザーのidを与える。|
|current_user|sessions_helper.rb|〃|インスタンス変数@current_userが空であれば、データベースからsessionsハッシュの:user_idのidを持つユーザーをそこに代入する。|
|logged_in?|sessions_helper.rb|〃|ログインしてればtrue,してなければfalseを返す。|
|log_out|sessions_helper.rb|〃|現在のユーザーをログアウトする。|
|**remember**(remember (user))|sessions_helper.rb|〃|永続的セッションのためにユーザーをデータベースに記憶する|
|**forget**(forget (user))|sessions_helper.rb|〃|永続的セッションを放棄する|
|(private)downcase_email|user.rb|userモデル内のみ|メールアドレスを小文字にする。|
|**remember** (user.remember)|user.rb|userモデルで生成されたインスタンスからのみ|remember_tokenの取得、remember_digestの保存|
|**forget**(user.forget)|user.rb|〃|ユーザーのログイン情報を放棄する|
|authenticated?|user.rb|〃|渡されたトーけんがダイジェストと一致したらtrue|
|User.digest(string)|user.rb|userモデルオブジェクトからのみ|与えられた文字列をハッシュ化する|
|User.new_token|user.rb|〃|ランダムなトークンを返す。|
|is_logged_in?|test_helper.rb|テストフォルダ内でのみ有効|テストユーザーがログインしてればtrue,してなければfalseを返す。|

# ymlのお作法！
```
<% EMOTIONS.each do |id, data|%>
            <% emo_name=data['key'] %>
            <h2 style="color:<%= data['color'] %>"><%=I18n.t("emotions.#{emo_name}")%></h2>            
<%end%>
```
## 注意点
- ハッシュのキーの呼び出しの際、キーは文字列として扱われることからシンボルではなくクオーテーションを用いること
- load_fileでymlファイルを読み込むとこの仕様(クオーテーション型)になるみたい
- ymlファイルの読み込みはconfig/initializers/emotions.rbにあり、load_fileすると、一番外側を読み取る。emotionsの中にidさらに中にkey,colorがある場合、普通にloadにすると、ここからkeyやcolorを指定しても参照することが叶わないため、emotionsを指定してあると言うわけ
- 現開発環境では、EMOTIONS[id][key]などで呼べる。


