class CreateDiaries < ActiveRecord::Migration[7.0]
  def change
    create_table :diaries do |t|
      # ユーザーとの紐付け
      t.references :user, null: false, foreign_key: true
      # 感情の種類(感情id)
      t.integer :emo_1, null: false
      t.integer :emo_2, null: true
      t.integer :emo_3, null: true
      # 感情の割合(合計100)
      t.integer :rate_1, null: false
      t.integer :rate_2, null: true
      t.integer :rate_3, null: true
      # 出来事
      t.text :content
      # 表示用フラグ(1:表示、0:非表示)
      t.boolean :flag, default: false, null: false
      # 記録した日数
      t.integer :day_no, null: false
      # 今日何枚目の葉か
      t.integer :seq_no, null:false
      
      t.timestamps
    end
    add_index :diaries, [:user_id, :day_no, :seq_no], unique: true
  end
end
