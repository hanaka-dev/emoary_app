require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    log_in_as(@user)
    get settings_path(edit: 1)
    assert_template 'users/show'
    patch user_path(@user), params: {  user:{  name: "",
                                                email: "foo@invalid",
                                                password:              "foo",
                                                password_confirmation: "bar" } }
    assert_select 'div#error_explanation'
  end

  test "successful edit" do
    log_in_as(@user)
    get settings_path(edit: 1)
    assert_template 'users/show'
    name = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { name: name,
                                              email: email,
                                              password:              "", 
                                              password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to settings_path
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email
  end
end