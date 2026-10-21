# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

class LoadingTest < Minitest::Test
  LIB = File.expand_path('../lib', __dir__)

  RAILS_APP = <<~RUBY.freeze
    require "rails"
    require "active_model/railtie"
    require "tincture"

    class App < Rails::Application
      config.root = #{Dir.mktmpdir.inspect}
      config.eager_load = false
      config.logger = Logger.new(nil)
      config.secret_key_base = "test"
    end

    App.initialize!
  RUBY

  def test_works_with_plain_ruby_without_loading_active_model
    output = ruby('require "tincture"; print Tincture::Color.parse("red").hex, " ", defined?(ActiveModel).inspect')

    assert_equal '#ff0000 nil', output
  end

  def test_loads_without_yaml
    assert_equal 'nil', ruby('require "tincture"; print defined?(YAML).inspect')
  end

  def test_registers_the_attribute_types_when_a_rails_app_boots
    output = ruby("#{RAILS_APP}\nprint ActiveModel::Type.lookup(:color).class, ' ', ActiveModel::Type.lookup(:colour).class")

    assert_equal 'Tincture::Type Tincture::Type', output
  end

  private

  def ruby(script)
    IO.popen([RbConfig.ruby, '-I', LIB, '-e', script], err: %i[child out], &:read)
  end
end
