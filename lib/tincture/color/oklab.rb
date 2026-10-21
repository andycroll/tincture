# frozen_string_literal: true

module Tincture
  class Color # rubocop:disable Style/Documentation
    # Oklab and its cylindrical form Oklch, where equal steps look equally
    # different. Mixed into Color.
    module Oklab
      # Added to Color itself.
      module ClassMethods
        # Builds a colour from Oklab lightness (0–1) and its `a` (green–red)
        # and `b` (blue–yellow) axes.
        #
        #: (Numeric lightness, Numeric green_red, Numeric blue_yellow, ?Numeric alpha) -> Color
        def oklab(lightness, green_red, blue_yellow, alpha = 1.0) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          lightness = lightness.clamp(0, 1)

          l, m, s = [
            lightness + (0.3963377774 * green_red) + (0.2158037573 * blue_yellow),
            lightness - (0.1055613458 * green_red) - (0.0638541728 * blue_yellow),
            lightness - (0.0894841775 * green_red) - (1.2914855480 * blue_yellow)
          ].map { it**3 }

          linear = [
            (4.0767416621 * l) - (3.3077115913 * m) + (0.2309699292 * s),
            (-1.2684380046 * l) + (2.6097574011 * m) - (0.3413193965 * s),
            (-0.0041960863 * l) - (0.7034186147 * m) + (1.7076147010 * s)
          ]

          rgb(*linear.map { gamma_encoded(it) * 255 }, alpha)
        end

        # Builds a colour from Oklab lightness (0–1), chroma and a hue in
        # degrees.
        #
        #: (Numeric lightness, Numeric chroma, Numeric hue, ?Numeric alpha) -> Color
        def oklch(lightness, chroma, hue, alpha = 1.0)
          chroma = [chroma, 0].max
          radians = hue * Math::PI / 180
          oklab(lightness, chroma * Math.cos(radians), chroma * Math.sin(radians), alpha)
        end

        private

        def gamma_encoded(linear)
          linear = linear.clamp(0.0, 1.0)
          linear <= 0.0031308 ? linear * 12.92 : (1.055 * (linear**(1 / 2.4))) - 0.055
        end
      end

      # Oklab lightness (0–1) and its `a` and `b` axes, to four decimal
      # places.
      #
      #: () -> [Float, Float, Float]
      def oklab = oklab_components.map { rounded(it, 4) }

      # Oklab lightness (0–1), chroma to four decimal places, and hue in
      # degrees to two.
      #
      #: () -> [Float, Float, Float]
      def oklch
        lightness, a, b = oklab_components
        chroma = rounded(Math.hypot(a, b), 4)
        angle = chroma.zero? ? 0 : Math.atan2(b, a) * 180 / Math::PI

        [rounded(lightness, 4), chroma, rounded(angle, 2) % 360]
      end

      # `"oklab(0.628 0.2249 0.1258)"`, with `/ alpha` when translucent.
      #
      #: () -> String
      def css_oklab = css_function('oklab', oklab)

      # `"oklch(0.628 0.2577 29.23)"`, with `/ alpha` when translucent.
      #
      #: () -> String
      def css_oklch = css_function('oklch', oklch)

      protected

      def oklab_components # :nodoc: # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        red, green, blue = linear_rgb

        l, m, s = [
          (0.4122214708 * red) + (0.5363325363 * green) + (0.0514459929 * blue),
          (0.2119034982 * red) + (0.6806995451 * green) + (0.1073969566 * blue),
          (0.0883024619 * red) + (0.2817188376 * green) + (0.6299787005 * blue)
        ].map { Math.cbrt(it) }

        [
          (0.2104542553 * l) + (0.7936177850 * m) - (0.0040720468 * s),
          (1.9779984951 * l) - (2.4285922050 * m) + (0.4505937099 * s),
          (0.0259040371 * l) + (0.7827717662 * m) - (0.8086757660 * s)
        ]
      end

      private

      def mixed_toward(other, amount)
        lightness, a, b = oklab_components.zip(other.oklab_components).map do |mine, theirs|
          mine + ((theirs - mine) * amount)
        end
        Color.oklab(lightness, a, b, alpha)
      end
    end

    include Oklab
    extend Oklab::ClassMethods
  end
end
