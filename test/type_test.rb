# frozen_string_literal: true

require 'test_helper'
require 'support/active_record'

class TypeActiveModelTest < Minitest::Test
  class Swatch
    include ActiveModel::API
    include ActiveModel::Attributes

    attribute :accent, :color
  end

  def test_casts_css_strings_to_a_color
    assert_equal Tincture::Color.rgb(255, 136, 0), Swatch.new(accent: '#ff8800').accent
    assert_equal Tincture::Color.rgb(255, 136, 0), Swatch.new(accent: 'hsl(32 100% 50%)').accent
  end

  def test_keeps_an_assigned_color
    color = Tincture::Color.rgb(1, 2, 3)

    assert_same color, Swatch.new(accent: color).accent
  end

  def test_casts_blank_and_unparseable_input_to_nil
    assert_nil Swatch.new(accent: '').accent
    assert_nil Swatch.new(accent: nil).accent
    assert_nil Swatch.new(accent: 'orange-ish').accent
  end

  def test_serializes_to_hash_prefixed_hex_by_default
    assert_equal '#ff8800', Tincture::Type.new.serialize(Tincture::Color.rgb(255, 136, 0))
    assert_nil Tincture::Type.new.serialize(nil)
  end
end

class TypeActiveRecordTest < Minitest::Test
  class Branding < ActiveRecord::Base
    attribute :accent_color_hex, :color, prefix: false

    validates :accent_color_hex, color: true
  end

  def setup
    ActiveRecord::Base.connection.create_table :brandings, force: true do |t|
      t.string :accent_color_hex
    end
    Branding.reset_column_information
  end

  def teardown
    ActiveRecord::Base.connection.drop_table :brandings, if_exists: true
  end

  def test_stores_bare_hex_when_prefix_is_off_and_reads_it_back_as_a_color
    branding = Branding.create!(accent_color_hex: 'rgb(171 178 186)')

    assert_equal 'abb2ba', Branding.connection.select_value('SELECT accent_color_hex FROM brandings')
    assert_equal Tincture::Color.parse('#abb2ba'), branding.reload.accent_color_hex
  end

  def test_reads_existing_bare_hex_rows
    Branding.connection.execute("INSERT INTO brandings (accent_color_hex) VALUES ('ABB2BA')")

    assert_equal '#abb2ba', Branding.sole.accent_color_hex.hex
  end

  def test_queries_by_any_css_form_of_a_color
    branding = Branding.create!(accent_color_hex: '#abb2ba')

    assert_equal branding, Branding.find_by(accent_color_hex: 'hsl(212 9.8% 70%)')
  end

  def test_does_not_mark_the_attribute_dirty_for_another_spelling_of_the_same_color
    branding = Branding.create!(accent_color_hex: '#abb2ba')
    branding.accent_color_hex = 'rgb(171, 178, 186)'

    refute branding.accent_color_hex_changed?
  end

  def test_validator_rejects_unparseable_input
    branding = Branding.new(accent_color_hex: 'orange-ish')

    assert_predicate branding, :invalid?
    assert_equal ['is not a valid color'], branding.errors[:accent_color_hex]
  end

  def test_validator_leaves_blank_and_valid_input_alone
    assert_predicate Branding.new(accent_color_hex: ''), :valid?
    assert_predicate Branding.new(accent_color_hex: '#abb2ba'), :valid?
  end
end
