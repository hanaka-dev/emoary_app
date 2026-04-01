require "test_helper"

class DiariesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @diary = diaries(:one)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Diary.count" do
      post diaries_path, params: {  diary: {  content: "Lorem ipsum"  } }
    end
    # logged_in_user は未ログイン時 root_path（ログイン画面）へ飛ばす
    assert_redirected_to root_url
  end
end
