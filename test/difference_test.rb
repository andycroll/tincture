# frozen_string_literal: true

require 'test_helper'

class DifferenceTest < Minitest::Test
  # Sharma, Wu and Dalal's reference pairs: L*a*b* twice, then ΔE00.
  # https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/
  SHARMA_PAIRS = File.readlines(File.expand_path('fixtures/ciede2000.txt', __dir__)).map { it.split.map(&:to_f) }

  def test_matches_every_ciede2000_reference_pair
    SHARMA_PAIRS.each do |row|
      assert_in_delta row.last, Tincture::Difference.ciede2000(row[0, 3], row[3, 3]), 0.0001
    end
  end

  def test_is_symmetric
    first, second = SHARMA_PAIRS.first.each_slice(3).first(2)

    assert_equal Tincture::Difference.ciede2000(first, second), Tincture::Difference.ciede2000(second, first)
  end
end

class ColorDifferenceTest < Minitest::Test
  RED = Tincture::Color.parse('red')

  def test_measures_delta_e_ok_by_default
    assert_in_delta 0.4526, RED.difference('white'), 0.0001
    assert_in_delta 0.0, RED.difference('#ff0000')
  end

  def test_measures_ciede2000_from_d65_l_a_b
    red_lab = [53.2408, 80.0925, 67.2032]
    white_lab = [100.0, 0.0, 0.0]

    assert_in_delta Tincture::Difference.ciede2000(red_lab, white_lab), RED.difference('white', formula: :ciede2000),
                    0.001
  end

  def test_rejects_an_unknown_formula
    assert_raises(ArgumentError) { RED.difference('white', formula: :cie76) }
  end
end

class ColorWcagLevelTest < Minitest::Test
  def test_checks_a_wcag_level_for_normal_and_large_text
    grey = Tincture::Color.parse('#767676')

    assert grey.readable_on?('white')
    refute grey.readable_on?('white', level: :aaa)
    assert grey.readable_on?('white', level: :aaa, large: true)
    assert Tincture::Color.parse('#949494').readable_on?('white', large: true)
    refute Tincture::Color.parse('#949494').readable_on?('white')
  end

  def test_names_the_highest_wcag_level_a_pairing_reaches
    assert_equal :aaa, Tincture::Color.parse('black').contrast_level('white')
    assert_equal :aa, Tincture::Color.parse('#767676').contrast_level('white')
    assert_equal :aa_large, Tincture::Color.parse('#949494').contrast_level('white')
    assert_nil Tincture::Color.parse('#cccccc').contrast_level('white')
  end
end

class ColorNearestReadableTest < Minitest::Test
  ORANGE = Tincture::Color.parse('#ff8800')

  def test_returns_itself_when_already_readable
    grey = Tincture::Color.parse('#767676')

    assert_same grey, grey.nearest_readable_on('white')
  end

  def test_darkens_just_enough_on_a_light_background_keeping_the_hue
    readable = ORANGE.nearest_readable_on('white')

    assert readable.readable_on?('white')
    assert_operator readable.contrast_ratio('white'), :<, 4.6
    assert_in_delta ORANGE.oklch.last, readable.oklch.last, 2
  end

  def test_lightens_on_a_dark_background
    readable = Tincture::Color.parse('navy').nearest_readable_on('#111111', level: :aaa)

    assert readable.readable_on?('#111111', level: :aaa)
    assert_operator readable.luminance, :>, Tincture::Color.parse('navy').luminance
  end

  def test_returns_nil_when_even_black_or_white_cannot_reach_the_level
    assert_nil Tincture::Color.parse('red').nearest_readable_on('#777777', level: :aaa)
  end
end
