# frozen_string_literal: true

module Tincture
  # Raised by Color.parse for input that is not a CSS colour.
  class InvalidColor < ArgumentError; end

  # An sRGB colour: 8-bit `red`, `green` and `blue` channels and an `alpha`
  # from 0 to 1. Immutable.
  #
  # Parses CSS hex, named, `rgb()`, `hsl()`, `hwb()`, `oklab()` and `oklch()`
  # colours. Every output is derived from the 8-bit channels, so a colour
  # stored as hex round-trips through any of them. Colours outside sRGB, such
  # as a high-chroma `oklch()`, clip to the nearest channel values.
  #
  #     color = Tincture::Color.parse("orange")
  #     color.css_hsl        # => "hsl(38.8 100% 50%)"
  #     color.contrast_color # => Tincture::Color::BLACK
  #
  # Each part lives in a module mixed into this class: Parsing (`parse`), Hsl
  # (HSL, HWB, HSV), Oklab (Oklab, Oklch), Contrast (WCAG, black or white
  # text) and Comparison (ΔE).
  #
  # Conversions follow [CSS Color 4](https://www.w3.org/TR/css-color-4/) and
  # [Oklab](https://bottosson.github.io/posts/oklab/).
  class Color < Data.define(:red, :green, :blue, :alpha)
    LINEAR_CHANNELS = Array.new(256) do |byte| # :nodoc:
      fraction = byte / 255.0
      fraction <= 0.04045 ? fraction / 12.92 : ((fraction + 0.055) / 1.055)**2.4
    end.freeze

    # Builds a colour from 0–255 channels and a 0–1 alpha. Out-of-range
    # values clamp, as they do in CSS.
    #
    #: (Numeric red, Numeric green, Numeric blue, ?Numeric alpha) -> Color
    def self.rgb(red, green, blue, alpha = 1.0)
      red, green, blue = [red, green, blue].map { it.clamp(0, 255).round }
      new(red:, green:, blue:, alpha: alpha.clamp(0.0, 1.0).to_f)
    end

    # `"#ff8800"`, or `"#ff880080"` when translucent.
    #
    #: () -> String
    def hex
      bytes = opaque? ? rgb : [*rgb, alpha_byte]
      "##{bytes.map { format('%02x', it) }.join}"
    end

    alias to_s hex

    # JSON renders a colour as its hex string.
    #
    #: (*untyped) -> String
    def as_json(*) = hex

    # Red, green and blue, each 0–255.
    #
    #: () -> [Integer, Integer, Integer]
    def rgb = [red, green, blue]

    # `"rgb(255 136 0)"` or `"rgb(255 136 0 / 0.5)"`.
    #
    #: () -> String
    def css_rgb = css_function('rgb', rgb)

    # Whether the colour has no transparency at 8-bit precision.
    #
    #: () -> bool
    def opaque? = alpha_byte == 255

    private

    def alpha_byte = (alpha * 255).round

    def channel_fractions = rgb.map { it / 255.0 }

    def linear_rgb = rgb.map { LINEAR_CHANNELS[it] }

    # Adding 0.0 turns -0.0 into 0.0, so CSS never shows "-0".
    def rounded(number, digits) = number.round(digits) + 0.0

    def css_function(name, components, percentages: false)
      first, *rest = components.map { css_number(it) }
      rest = rest.map { "#{it}%" } if percentages
      alpha = " / #{css_number(self.alpha.round(3))}" unless opaque?

      "#{name}(#{[first, *rest].join(' ')}#{alpha})"
    end

    def css_number(number) = number.to_s.delete_suffix('.0')
  end
end
