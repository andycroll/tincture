# frozen_string_literal: true

module Tincture
  class Color
    # How different two colours look. The formulas live in
    # Tincture::Difference. Mixed into Color.
    module Comparison
      D65_WHITE = [0.95047, 1.0, 1.08883].freeze # :nodoc:

      # How different two colours look (ΔE). `formula: :oklab` (the default)
      # is ΔE OK, where under about 0.02 is hard to see. `formula:
      # :ciede2000` is ΔE00, where about 1 is just visible. See
      # Tincture::Difference.
      #
      #     Tincture::Color.parse("red").difference("white") # => 0.4526…
      #
      #: (String | Color other, ?formula: :oklab | :ciede2000) -> Float
      def difference(other, formula: :oklab)
        other = Color.parse(other)

        case formula
        when :oklab then Difference.oklab(oklab_components, other.oklab_components)
        when :ciede2000 then Difference.ciede2000(lab_components, other.lab_components)
        else raise ArgumentError, "unknown formula #{formula.inspect}, use :oklab or :ciede2000"
        end
      end

      protected

      # CIELAB against the D65 white point, as sRGB tools usually report it.
      def lab_components # :nodoc:
        red, green, blue = linear_rgb

        x, y, z = [
          ((0.4124564 * red) + (0.3575761 * green) + (0.1804375 * blue)) / D65_WHITE[0],
          ((0.2126729 * red) + (0.7151522 * green) + (0.0721750 * blue)) / D65_WHITE[1],
          ((0.0193339 * red) + (0.1191920 * green) + (0.9503041 * blue)) / D65_WHITE[2]
        ].map { it > (6 / 29.0)**3 ? Math.cbrt(it) : (it / (3 * ((6 / 29.0)**2))) + (4 / 29.0) }

        [(116 * y) - 16, 500 * (x - y), 200 * (y - z)]
      end
    end

    include Comparison
  end
end
