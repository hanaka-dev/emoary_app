require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
    test "full title helper" do
        assert_equal "Home | Emoary", full_title("Home")
        assert_equal "Help | Emoary", full_title("Help")
    end
end
