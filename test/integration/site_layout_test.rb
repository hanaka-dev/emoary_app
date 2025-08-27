require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest
  test "layout links" do
    get home_path
    assert_template 'static_pages/home'
    # 現在helpへのリンクのみ。増えたら増やそう！
    assert_select "a[href=?]", help_path
    assert_select "a[href=?]", settings_path
  end
end
