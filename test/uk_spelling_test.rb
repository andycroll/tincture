# frozen_string_literal: true

require 'test_helper'
require 'support/active_record'

class UkSpellingTest < Minitest::Test
  class Branding < ActiveRecord::Base
    attribute :accent_colour, :colour

    validates :accent_colour, colour: true
  end

  def setup
    ActiveRecord::Base.connection.create_table :brandings, force: true do |t|
      t.string :accent_colour
    end
    Branding.reset_column_information
  end

  def teardown
    ActiveRecord::Base.connection.drop_table :brandings, if_exists: true
  end

  def test_colour_is_color
    assert_same Tincture::Color, Tincture::Colour
  end

  def test_invalidcolour_is_invalidcolor
    assert_raises(Tincture::InvalidColour) { Tincture::Colour.parse('orange-ish') }
  end

  def test_casts_through_the_colour_type
    assert_equal Tincture::Colour.rgb(255, 136, 0), Branding.new(accent_colour: '#ff8800').accent_colour
  end

  def test_colour_validator_rejects_unparseable_input_in_uk_spelling
    branding = Branding.new(accent_colour: 'orange-ish')

    assert_predicate branding, :invalid?
    assert_equal ['is not a valid colour'], branding.errors[:accent_colour]
  end
end
