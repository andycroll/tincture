# frozen_string_literal: true

module Tincture
  class Color
    # HSL and its relatives HWB and HSV, which share its hue angle. Mixed into
    # Color.
    module Hsl
      # Added to Color itself.
      module ClassMethods
        # Builds a colour from a hue in degrees, and saturation and lightness
        # percentages (0–100).
        #
        #: (Numeric hue, Numeric saturation, Numeric lightness, ?Numeric alpha) -> Color
        def hsl(hue, saturation, lightness, alpha = 1.0)
          channels = hsl_channels(hue, saturation / 100.0, lightness / 100.0)
          rgb(*channels.map { it * 255 }, alpha)
        end

        # Builds a colour from a hue in degrees, and whiteness and blackness
        # percentages (0–100). Whiteness and blackness that sum past 100%
        # give a grey.
        #
        #: (Numeric hue, Numeric whiteness, Numeric blackness, ?Numeric alpha) -> Color
        def hwb(hue, whiteness, blackness, alpha = 1.0)
          whiteness = whiteness.clamp(0, 100) / 100.0
          blackness = blackness.clamp(0, 100) / 100.0

          channels =
            if whiteness + blackness >= 1
              [whiteness / (whiteness + blackness)] * 3
            else
              hsl_channels(hue, 1, 0.5).map { (it * (1 - whiteness - blackness)) + whiteness }
            end

          rgb(*channels.map { it * 255 }, alpha)
        end

        # Builds a colour from a hue in degrees, and saturation and value
        # percentages (0–100), as colour pickers use. Not a CSS format.
        #
        #: (Numeric hue, Numeric saturation, Numeric value, ?Numeric alpha) -> Color
        def hsv(hue, saturation, value, alpha = 1.0)
          hwb(hue, (100 - saturation) * value / 100.0, 100 - value, alpha)
        end

        private

        def hsl_channels(hue, saturation, lightness)
          saturation = saturation.clamp(0, 1)
          lightness = lightness.clamp(0, 1)
          amount = saturation * [lightness, 1 - lightness].min

          [0, 8, 4].map do |offset|
            k = (offset + (hue / 30.0)) % 12
            lightness - (amount * [-1, [k - 3, 9 - k, 1].min].max)
          end
        end
      end

      # Hue in degrees, saturation and lightness as percentages, to one
      # decimal place.
      #
      #: () -> [Float, Float, Float]
      def hsl
        max, min = channel_fractions.minmax.reverse
        lightness = (max + min) / 2
        saturation = max == min ? 0 : (max - lightness) / [lightness, 1 - lightness].min

        [hue, rounded(saturation * 100, 1), rounded(lightness * 100, 1)]
      end

      # Hue in degrees, whiteness and blackness as percentages, to one
      # decimal place.
      #
      #: () -> [Float, Float, Float]
      def hwb
        max, min = channel_fractions.minmax.reverse
        [hue, rounded(min * 100, 1), rounded((1 - max) * 100, 1)]
      end

      # Hue in degrees, saturation and value as percentages, to one decimal
      # place.
      #
      #: () -> [Float, Float, Float]
      def hsv
        max, min = channel_fractions.minmax.reverse
        saturation = max.zero? ? 0 : (max - min) / max

        [hue, rounded(saturation * 100, 1), rounded(max * 100, 1)]
      end

      # `"hsl(32 100% 50%)"` or `"hsl(32 100% 50% / 0.5)"`.
      #
      #: () -> String
      def css_hsl = css_function('hsl', hsl, percentages: true)

      # `"hwb(32 0% 0%)"` or `"hwb(32 0% 0% / 0.5)"`.
      #
      #: () -> String
      def css_hwb = css_function('hwb', hwb, percentages: true)

      private

      def hue
        red, green, blue = channel_fractions
        max, min = channel_fractions.minmax.reverse
        delta = max - min

        sector =
          if delta.zero? then 0
          elsif max == red then ((green - blue) / delta) % 6
          elsif max == green then ((blue - red) / delta) + 2
          else ((red - green) / delta) + 4
          end

        rounded(sector * 60, 1) % 360
      end
    end

    include Hsl
    extend Hsl::ClassMethods
  end
end
