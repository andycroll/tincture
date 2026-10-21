# frozen_string_literal: true

require 'yaml'

module Tincture
  class Color # rubocop:disable Style/Documentation
    # Reads CSS colour strings: hex, named colours and the `rgb()`, `hsl()`,
    # `hwb()`, `oklab()` and `oklch()` functions. Extends Color, so its
    # methods are called on the class: `Tincture::Color.parse`.
    module Parsing
      HEX = /
        \A
        \#?                   # optional leading hash
        (?<digits>
          \h{3,4}             # rgb or rgba shorthand
          | \h{6}             # rrggbb
          | \h{8}             # rrggbbaa
        )
        \z
      /x # :nodoc:

      FUNCTION = /
        \A
        (?<name>[a-z]+)       # rgb, hsla, oklch…
        \(
        (?<arguments>[^)]*)   # everything between the parentheses
        \)
        \z
      /xi # :nodoc:

      TOKEN = /
        \A
        (?<number>
          [+-]?               # optional sign
          (?:
            \d+(?:\.\d*)?     # integer, optional decimals: 1, 1., 1.5
            | \.\d+           # bare decimals: .5
          )
          (?:e[+-]?\d+)?      # optional exponent: 1e3
        )
        (?<unit>%|deg|grad|rad|turn)?
        \z
      /xi # :nodoc:

      CHANNEL = { nil => 1, '%' => 255r / 100 }.freeze # :nodoc:
      FRACTION = { nil => 1, '%' => 1r / 100 }.freeze # :nodoc:
      PERCENTAGE = { nil => 1, '%' => 1 }.freeze # :nodoc:
      HUE = { nil => 1, 'deg' => 1, 'grad' => 0.9, 'rad' => 180 / Math::PI, 'turn' => 360 }.freeze # :nodoc:
      OK_AXIS = { nil => 1, '%' => 4r / 1000 }.freeze # :nodoc:

      UNITS = {
        'rgb' => [CHANNEL, CHANNEL, CHANNEL, FRACTION],
        'hsl' => [HUE, PERCENTAGE, PERCENTAGE, FRACTION],
        'hwb' => [HUE, PERCENTAGE, PERCENTAGE, FRACTION],
        'oklab' => [FRACTION, OK_AXIS, OK_AXIS, FRACTION],
        'oklch' => [FRACTION, OK_AXIS, HUE, FRACTION]
      }.freeze # :nodoc:

      # Only rgb() and hsl() take the comma syntax and the rgba()/hsla() names.
      LEGACY = { 'rgb' => 'rgb', 'rgba' => 'rgb', 'hsl' => 'hsl', 'hsla' => 'hsl' }.freeze # :nodoc:

      # Parses a CSS colour string. Returns a Color unchanged.
      #
      #     Tincture::Color.parse("#ff8800")
      #     Tincture::Color.parse("rebeccapurple")
      #     Tincture::Color.parse("oklch(0.7 0.18 50 / 50%)")
      #
      # Raises InvalidColor for anything else.
      #
      #: (String | Color input) -> Color
      def parse(input)
        return input if input.is_a?(Color)

        string = input.to_s.strip
        color = hex_color(string) || NAMED[string.downcase] || function_color(string)
        color || raise(InvalidColor, "#{input.inspect} is not a CSS color")
      end

      private

      def hex_color(string)
        digits = HEX.match(string)&.[](:digits)
        return unless digits

        digits = digits.chars.map { it * 2 }.join if digits.length <= 4
        red, green, blue, alpha = digits.scan(/../).map(&:hex)
        rgb(red, green, blue, (alpha || 255) / 255.0)
      end

      def function_color(string)
        match = FUNCTION.match(string)
        return unless match

        name = match[:name].downcase
        constructor = LEGACY.fetch(name, name)
        units = UNITS[constructor]
        values = units && function_values(match[:arguments], units, legacy: LEGACY.key?(name))
        public_send(constructor, *values) if values
      end

      def function_values(arguments, units, legacy:)
        tokens = function_tokens(arguments, legacy:)
        return unless tokens

        values = tokens.zip(units).map { |token, scale| number(token, scale) }
        values unless values.include?(nil)
      end

      # Legacy syntax separates with commas and takes alpha fourth; modern
      # syntax separates with spaces and takes alpha after a slash.
      def function_tokens(arguments, legacy:)
        if arguments.include?(',')
          legacy_tokens(arguments) if legacy
        else
          modern_tokens(arguments)
        end
      end

      def legacy_tokens(arguments)
        tokens = arguments.split(',', -1).map(&:strip)
        tokens if tokens.size.between?(3, 4)
      end

      def modern_tokens(arguments)
        channels, alpha, *extra = arguments.split('/')
        tokens = channels.to_s.split
        [*tokens, *alpha&.strip] if tokens.size == 3 && extra.empty?
      end

      def number(token, scale)
        match = TOKEN.match(token)
        return unless match

        unit = match[:unit]&.downcase
        match[:number].to_r * scale[unit] if scale.key?(unit)
      end
    end

    extend Parsing

    # CSS named colours, keyed by lowercase name.
    NAMED = YAML.load_file(File.expand_path('../named_colors.yml', __dir__)).transform_values { parse(it) }.freeze
  end
end
