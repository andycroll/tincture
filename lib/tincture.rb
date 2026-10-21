# frozen_string_literal: true

require_relative 'tincture/version'
require_relative 'tincture/difference'
require_relative 'tincture/color'
require_relative 'tincture/color/parsing'
require_relative 'tincture/color/hsl'
require_relative 'tincture/color/oklab'
require_relative 'tincture/color/contrast'
require_relative 'tincture/color/comparison'

# Colour values for plain Ruby, with an optional Active Model integration.
#
# - Tincture::Color parses, converts and compares colours.
# - Tincture::Type casts model attributes declared `:color` or `:colour`.
# - ActiveModel::Validations::ColorValidator rejects input the type could not
#   parse.
#
# The type and validator need `require "tincture/active_model"`. Rails apps
# load it automatically.
#
# Every name has a UK alias: `Colour`, `InvalidColour`, `:colour`.
module Tincture
  Colour = Color
  InvalidColour = InvalidColor
end

# :nocov:
require_relative 'tincture/railtie' if defined?(Rails::Railtie)
# :nocov:
