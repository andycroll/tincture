# frozen_string_literal: true

module Tincture
  # Colour difference (ΔE) formulas. Color#difference is the usual way in;
  # these take colour space coordinates directly.
  module Difference
    module_function

    # ΔE OK: straight-line distance between two Oklab colours, as CSS Color 4
    # measures it. Differences under about 0.02 are hard to see.
    #
    #: ([Float, Float, Float] first, [Float, Float, Float] second) -> Float
    def oklab(first, second)
      Math.sqrt(first.zip(second).sum { |a, b| (a - b)**2 })
    end

    # CIEDE2000 (ΔE00) between two CIELAB colours, the print and paint
    # standard. A difference of about 1 is just visible.
    #
    # Follows [Sharma, Wu and Dalal](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/ciede2000noteCRNA.pdf),
    # with the weighting factors kL, kC and kH all 1.
    #
    #: ([Float, Float, Float] first, [Float, Float, Float] second) -> Float
    def ciede2000(first, second) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      (l1, a1, b1), (l2, a2, b2) = first, second

      chroma_mean = (Math.hypot(a1, b1) + Math.hypot(a2, b2)) / 2
      g = 0.5 * (1 - chroma_weight(chroma_mean))
      a1 *= 1 + g
      a2 *= 1 + g

      c1 = Math.hypot(a1, b1)
      c2 = Math.hypot(a2, b2)
      h1 = hue_angle(a1, b1)
      h2 = hue_angle(a2, b2)
      chromatic = c1 * c2 != 0

      delta_l = l2 - l1
      delta_c = c2 - c1
      delta_h = 2 * Math.sqrt(c1 * c2) * Math.sin(radians(hue_difference(h1, h2, chromatic) / 2))

      l_mean = (l1 + l2) / 2
      c_mean = (c1 + c2) / 2
      h_mean = hue_mean(h1, h2, chromatic)

      t = 1 - (0.17 * Math.cos(radians(h_mean - 30))) + (0.24 * Math.cos(radians(2 * h_mean))) +
          (0.32 * Math.cos(radians((3 * h_mean) + 6))) - (0.20 * Math.cos(radians((4 * h_mean) - 63)))

      s_l = 1 + (0.015 * ((l_mean - 50)**2) / Math.sqrt(20 + ((l_mean - 50)**2)))
      s_c = 1 + (0.045 * c_mean)
      s_h = 1 + (0.015 * c_mean * t)
      rotation = -Math.sin(radians(60 * Math.exp(-((h_mean - 275) / 25)**2))) * 2 * chroma_weight(c_mean)

      lightness = delta_l / s_l
      chroma = delta_c / s_c
      hue = delta_h / s_h
      Math.sqrt((lightness**2) + (chroma**2) + (hue**2) + (rotation * chroma * hue))
    end

    def chroma_weight(chroma) # :nodoc:
      Math.sqrt((chroma**7) / ((chroma**7) + (25.0**7)))
    end

    def hue_angle(green_red, blue_yellow) # :nodoc:
      green_red.zero? && blue_yellow.zero? ? 0 : Math.atan2(blue_yellow, green_red) * 180 / Math::PI % 360
    end

    def hue_difference(first_hue, second_hue, chromatic) # :nodoc:
      difference = second_hue - first_hue

      if !chromatic then 0
      elsif difference > 180 then difference - 360
      elsif difference < -180 then difference + 360
      else difference
      end
    end

    def hue_mean(first_hue, second_hue, chromatic) # :nodoc:
      sum = first_hue + second_hue

      if !chromatic then sum
      elsif (first_hue - second_hue).abs <= 180 then sum / 2
      elsif sum < 360 then (sum + 360) / 2
      else (sum - 360) / 2
      end
    end

    def radians(degrees) = degrees * Math::PI / 180 # :nodoc:

    private_class_method :chroma_weight, :hue_angle, :hue_difference, :hue_mean, :radians
  end
end
