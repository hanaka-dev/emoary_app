require "test_helper"

class DiariesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @diary = diaries(:one)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Diary.count" do
      post diaries_path, params: {  diary: {  content: "Lorem ipsum"  } }
    end
    assert_redirected_to login_path
  end
end
