class AddDemoAccountAndDemoSeed < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :demo_account, :boolean, default: false, null: false
    add_column :diaries, :demo_seed, :boolean, default: false, null: false
  end
end
