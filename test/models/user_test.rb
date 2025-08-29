require "test_helper"

class UserTest < ActiveSupport::TestCase
  
  def setup 
    @user = User.new(name: "Example User", email: "user@example.com",
                      password: "foobar", password_confirmation: "foobar" )
  end

  # ユーザーが正当
  test "should be valid" do
    assert @user.valid? 
  end
  
  # 存在性(name)
  test "name should be present" do
    @user.name = "  "
    assert_not @user.valid?
  end

  # 存在性(email)
  test "email should be present" do
    @user.email = " "
    assert_not @user.valid?
  end

  # 最大文字数(name)
  test "name should not be too long" do
    @user.name = "a"*51
    assert_not @user.valid?
  end

  # 最大文字数(email)
  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  # 正当なメアド
  test "email validation should accept valid address" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                          first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  # 不当なメアド
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                            foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  # ２度同じメアドの登録はさせない
  test "email addresses should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  # メアドが小文字で保存
  test "email addresses should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  # 存在性(パスワード)
  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end
  # パスワードの最小文字数
  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nill digest" do
    assert_not @user.authenticated?(:remember,'')
  end
end
