require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest
  test "layout links" do
    get root_path
    assert_template 'static_pages/home'
    # 現在helpへのリンクのみ。増えたら増やそう！
    assert_select "a[href=?]", help_path
  end
end
