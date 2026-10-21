# frozen_string_literal: true

require 'test_helper'

class ContrastColorTest < Minitest::Test
  BRIGHT_BLUE = Tincture::Color.parse('#0a7cff')
  DARK_GREY = Tincture::Color.parse('#1f2937')

  def test_uses_wcag_2_by_default_which_picks_black_on_bright_blue
    assert_equal Tincture::Color::BLACK, BRIGHT_BLUE.contrast_color
  end

  def test_picks_by_oklab_lightness_when_asked
    assert_equal Tincture::Color::WHITE, BRIGHT_BLUE.contrast_color(method: :oklab)
    assert_equal Tincture::Color::BLACK, Tincture::Color.parse('yellow').contrast_color(method: :oklab)
    assert_equal Tincture::Color::WHITE, Tincture::Color.parse('navy').contrast_color(method: :oklab)
  end

  def test_picks_the_best_of_the_given_candidates
    assert_equal DARK_GREY, Tincture::Color.parse('yellow').contrast_color(among: ['#1f2937', 'white'])
    assert_equal Tincture::Color::WHITE, Tincture::Color.parse('navy').contrast_color(among: [DARK_GREY, 'white'])
  end

  def test_picks_by_oklab_between_black_and_white_only_in_either_order
    assert_equal Tincture::Color::WHITE, BRIGHT_BLUE.contrast_color(among: %w[white black], method: :oklab)
    assert_raises(ArgumentError) { BRIGHT_BLUE.contrast_color(among: [DARK_GREY, 'white'], method: :oklab) }
  end

  def test_has_a_uk_spelling
    assert_equal BRIGHT_BLUE.contrast_color(method: :oklab), BRIGHT_BLUE.contrast_colour(method: :oklab)
  end

  def test_rejects_an_unknown_method
    assert_raises(ArgumentError) { BRIGHT_BLUE.contrast_color(method: :yiq) }
  end

  def test_points_to_tincture_apca_when_apca_is_asked_for_without_it
    error = assert_raises(ArgumentError) { BRIGHT_BLUE.contrast_color(method: :apca) }

    assert_match 'tincture-apca', error.message
  end
end
