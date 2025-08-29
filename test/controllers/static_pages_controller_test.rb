require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @base_title = "Emoary"
    @user = users(:michael)
  end

  test "should get root" do
    get root_url
    assert_response :success
  end

  test "should get home" do
    log_in_as(@user)
    get home_path
    assert_response :success
    assert_select "title", "Home | #{@base_title}"
  end

  test "should get help" do
    log_in_as(@user)
    get help_path
    assert_response :success
    assert_select "title", "Help | #{@base_title}"
  end

end
