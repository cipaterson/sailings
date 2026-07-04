require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "charter_color_style_tag emits a :root block of --charter-* variables" do
    html = charter_color_style_tag

    assert_includes html, "<style>"
    assert_includes html, ":root {"
    AppConfig.charter_colors.each do |name, color|
      assert_includes html, "--charter-#{name}: #{color};"
    end
  end

  test "charter_color_style_tag drops colors that could inject CSS" do
    html = charter_color_style_tag("evil" => "red; } body { display:none")
    assert_nil html
  end

  test "charter_color_style_tag keeps valid colors alongside invalid ones" do
    html = charter_color_style_tag("tbc" => "#abc", "bad" => "url(x)")
    assert_includes html, "--charter-tbc: #abc;"
    assert_not_includes html, "--charter-bad"
  end
end
