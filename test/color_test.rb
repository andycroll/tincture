# frozen_string_literal: true

require 'test_helper'
require 'json'

class ColorParseTest < Minitest::Test
  ORANGE = Tincture::Color.rgb(255, 136, 0)

  def test_parses_six_digit_hex_with_or_without_the_hash
    assert_equal ORANGE, Tincture::Color.parse('#ff8800')
    assert_equal ORANGE, Tincture::Color.parse('ff8800')
  end

  def test_parses_three_digit_hex
    assert_equal ORANGE, Tincture::Color.parse('#f80')
  end

  def test_parses_hex_case_insensitively_and_ignores_surrounding_whitespace
    assert_equal ORANGE, Tincture::Color.parse("  #FF8800\n")
  end

  def test_parses_alpha_from_eight_and_four_digit_hex
    assert_in_delta 128 / 255.0, Tincture::Color.parse('#ff880080').alpha
    assert_in_delta 136 / 255.0, Tincture::Color.parse('#f808').alpha
  end

  def test_parses_legacy_comma_separated_rgb_and_rgba
    assert_equal ORANGE, Tincture::Color.parse('rgb(255, 136, 0)')
    assert_equal ORANGE.with(alpha: 0.5), Tincture::Color.parse('rgba(255,136,0,0.5)')
  end

  def test_parses_modern_space_separated_rgb_with_a_slash_alpha
    assert_equal ORANGE, Tincture::Color.parse('RGB(255 136 0)')
    assert_equal ORANGE.with(alpha: 0.5), Tincture::Color.parse('rgb(255 136 0 / 50%)')
  end

  def test_parses_percentage_rgb_channels
    assert_equal Tincture::Color.rgb(255, 128, 0), Tincture::Color.parse('rgb(100% 50% 0%)')
  end

  def test_clamps_out_of_range_rgb_channels_like_css_does
    assert_equal Tincture::Color.rgb(255, 0, 0), Tincture::Color.parse('rgb(300, -5, 0)')
  end

  def test_parses_legacy_hsl_and_hsla
    assert_equal ORANGE, Tincture::Color.parse('hsl(32, 100%, 50%)')
    assert_equal ORANGE.with(alpha: 0.5), Tincture::Color.parse('hsla(32, 100%, 50%, 0.5)')
  end

  def test_parses_modern_hsl_with_hue_units_and_a_slash_alpha
    assert_equal ORANGE.with(alpha: 0.5), Tincture::Color.parse('hsl(32deg 100% 50% / 0.5)')
    assert_equal Tincture::Color.rgb(0, 255, 255), Tincture::Color.parse('hsl(0.5turn 100% 50%)')
  end

  def test_returns_a_color_unchanged
    assert_same ORANGE, Tincture::Color.parse(ORANGE)
  end

  def test_raises_invalidcolor_for_anything_else
    ['', 'orangey', '#ff888', '#gg0000', 'rgb(1, 2)', 'hsl(10, 20%)', 'rgb(1 2 3 4)', 'oklch(0.5 0.1)',
     'lab(50 20 30)', nil].each do |input|
      assert_raises(Tincture::InvalidColor, "expected #{input.inspect} to be rejected") do
        Tincture::Color.parse(input)
      end
    end
  end
end

class ColorConversionTest < Minitest::Test
  ORANGE = Tincture::Color.rgb(255, 136, 0)

  def test_builds_from_hsl_with_percentage_saturation_and_lightness
    assert_equal ORANGE, Tincture::Color.hsl(32, 100, 50)
  end

  def test_outputs_hex_adding_the_alpha_pair_only_when_translucent
    assert_equal '#ff8800', ORANGE.hex
    assert_equal '#ff880080', ORANGE.with(alpha: 0.5).hex
    assert_equal '#ff8800', ORANGE.to_s
  end

  def test_outputs_rgb_channels
    assert_equal [255, 136, 0], ORANGE.rgb
  end

  def test_outputs_hsl_components
    assert_equal [32.0, 100.0, 50.0], ORANGE.hsl
    assert_equal [0.0, 0.0, 100.0], Tincture::Color.rgb(255, 255, 255).hsl
  end

  def test_outputs_css_rgb_and_hsl_strings
    assert_equal 'rgb(255 136 0)', ORANGE.css_rgb
    assert_equal 'rgb(255 136 0 / 0.5)', ORANGE.with(alpha: 0.5).css_rgb
    assert_equal 'hsl(32 100% 50%)', ORANGE.css_hsl
    assert_equal 'hsl(212 9.8% 70% / 0.25)', Tincture::Color.parse('#abb2ba').with(alpha: 0.25).css_hsl
  end

  def test_round_trips_hex_through_its_css_hsl_string
    ['#abb2ba', '#0a7cff', '#123456', '#fefefe', '#010203'].each do |hex|
      assert_equal hex, Tincture::Color.parse(Tincture::Color.parse(hex).css_hsl).hex
    end
  end

  def test_round_trips_translucent_hex_through_every_css_form
    translucent = Tincture::Color.parse('#ff880080')

    assert_equal '#ff880080', Tincture::Color.parse(translucent.css_rgb).hex
    assert_equal '#ff880080', Tincture::Color.parse(translucent.css_hsl).hex
  end

  def test_is_immutable
    assert_predicate ORANGE, :frozen?
  end
end

class ColorNamedTest < Minitest::Test
  def test_parses_css_named_colors_case_insensitively
    assert_equal Tincture::Color.rgb(255, 165, 0), Tincture::Color.parse('orange')
    assert_equal Tincture::Color.rgb(102, 51, 153), Tincture::Color.parse(' RebeccaPurple ')
  end

  def test_parses_transparent_as_clear_black
    assert_equal Tincture::Color.rgb(0, 0, 0, 0), Tincture::Color.parse('transparent')
  end

  def test_keeps_the_names_in_a_frozen_hash
    assert_predicate Tincture::Color::NAMED, :frozen?
    assert_equal Tincture::Color.rgb(240, 248, 255), Tincture::Color::NAMED.fetch('aliceblue')
  end

  def test_reads_all_148_named_colors_and_transparent
    assert_equal 149, Tincture::Color::NAMED.size
  end
end

class ColorHwbHsvTest < Minitest::Test
  ORANGE = Tincture::Color.rgb(255, 136, 0)
  GREY_BLUE = Tincture::Color.parse('#abb2ba')

  def test_parses_hwb
    assert_equal ORANGE, Tincture::Color.parse('hwb(32 0% 0%)')
    assert_equal ORANGE.with(alpha: 0.5), Tincture::Color.parse('hwb(32deg 0% 0% / 50%)')
  end

  def test_normalises_hwb_whiteness_and_blackness_that_sum_past_100_to_grey
    assert_equal Tincture::Color.rgb(128, 128, 128), Tincture::Color.parse('hwb(0 60% 60%)')
  end

  def test_outputs_hwb_components_and_the_css_string
    assert_equal [212.0, 67.1, 27.1], GREY_BLUE.hwb
    assert_equal 'hwb(32 0% 0%)', ORANGE.css_hwb
  end

  def test_builds_from_and_outputs_hsv
    assert_equal ORANGE, Tincture::Color.hsv(32, 100, 100)
    assert_equal [212.0, 8.1, 72.9], GREY_BLUE.hsv
    assert_equal [0.0, 0.0, 0.0], Tincture::Color.rgb(0, 0, 0).hsv
  end

  def test_round_trips_hex_through_hwb_and_hsv
    ['#abb2ba', '#0a7cff', '#123456', '#fefefe', '#010203'].each do |hex|
      color = Tincture::Color.parse(hex)

      assert_equal hex, Tincture::Color.parse(color.css_hwb).hex
      assert_equal hex, Tincture::Color.hsv(*color.hsv).hex
    end
  end

  def test_rejects_legacy_comma_syntax_for_hwb
    assert_raises(Tincture::InvalidColor) { Tincture::Color.parse('hwb(32, 0%, 0%)') }
  end
end

class ColorOklabTest < Minitest::Test
  RED = Tincture::Color.rgb(255, 0, 0)

  def test_outputs_oklab_and_oklch_components
    assert_equal [0.628, 0.2249, 0.1258], RED.oklab
    assert_equal [0.628, 0.2577, 29.23], RED.oklch
    assert_equal [1.0, 0.0, 0.0], Tincture::Color.rgb(255, 255, 255).oklch
  end

  def test_outputs_css_oklab_and_oklch_strings
    assert_equal 'oklab(0.628 0.2249 0.1258)', RED.css_oklab
    assert_equal 'oklch(0.628 0.2577 29.23 / 0.5)', RED.with(alpha: 0.5).css_oklch
  end

  def test_parses_oklab_and_oklch_with_percentage_lightness
    assert_equal RED, Tincture::Color.parse('oklab(0.628 0.2249 0.1258)')
    assert_equal RED, Tincture::Color.parse('oklch(62.8% 0.2577 29.23deg)')
  end

  # 100% chroma is 0.4.
  def test_parses_percentage_chroma
    assert_equal RED, Tincture::Color.parse('oklch(0.628 64.425% 29.23)')
  end

  def test_builds_from_oklab_and_oklch
    assert_equal RED, Tincture::Color.oklab(0.628, 0.2249, 0.1258)
    assert_equal RED, Tincture::Color.oklch(0.628, 0.2577, 29.23)
  end

  def test_clips_colors_outside_srgb_instead_of_raising
    assert_equal Tincture::Color.rgb(0, 255, 0), Tincture::Color.parse('oklch(0.87 0.4 142)')
  end

  def test_round_trips_hex_through_oklab_and_oklch
    ['#abb2ba', '#0a7cff', '#123456', '#fefefe', '#010203'].each do |hex|
      color = Tincture::Color.parse(hex)

      assert_equal hex, Tincture::Color.parse(color.css_oklab).hex
      assert_equal hex, Tincture::Color.parse(color.css_oklch).hex
    end
  end
end

class ColorContrastTest < Minitest::Test
  def test_computes_wcag_relative_luminance
    assert_in_delta 1.0, Tincture::Color.rgb(255, 255, 255).luminance
    assert_in_delta 0.0, Tincture::Color.rgb(0, 0, 0).luminance
    assert_in_delta 0.2159, Tincture::Color.parse('#808080').luminance, 0.0001
  end

  def test_computes_the_wcag_contrast_ratio_either_way_round
    grey = Tincture::Color.parse('#767676')

    assert_in_delta 21.0, Tincture::Color.parse('black').contrast_ratio('white')
    assert_in_delta 4.54, grey.contrast_ratio('#ffffff'), 0.01
    assert_in_delta 4.54, Tincture::Color.parse('white').contrast_ratio(grey), 0.01
  end

  def test_picks_black_or_white_whichever_contrasts_more_as_the_contrast_color
    assert_equal Tincture::Color::BLACK, Tincture::Color.parse('yellow').contrast_color
    assert_equal Tincture::Color::BLACK, Tincture::Color.parse('#ff8800').contrast_color
    assert_equal Tincture::Color::WHITE, Tincture::Color.parse('navy').contrast_color
  end
end

class ColorJsonTest < Minitest::Test
  def test_serializes_to_hex_in_json
    color = Tincture::Color.parse('#ff8800')

    assert_equal '#ff8800', color.as_json
    assert_equal '{"accent":"#ff8800"}', JSON.generate({ accent: color })
  end
end
