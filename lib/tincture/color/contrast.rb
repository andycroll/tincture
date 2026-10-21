# frozen_string_literal: true

module Tincture
  class Color
    # WCAG 2 minimum contrast ratios.
    WCAG_RATIOS = { aa: { normal: 4.5, large: 3.0 }, aaa: { normal: 7.0, large: 4.5 } }.freeze

    # Oklab lightness of the grey where black and white text have equal APCA
    # contrast. #contrast_color with `method: :oklab` picks black above it.
    OKLAB_CONTRAST_THRESHOLD = 0.716

    # The dark default for #contrast_color.
    BLACK = NAMED.fetch('black')

    # The light default for #contrast_color.
    WHITE = NAMED.fetch('white')

    # WCAG 2 contrast, and picking text colours that read on a background.
    # Mixed into Color.
    module Contrast
      # Added to Color itself.
      module ClassMethods
        # Scores for #contrast_color methods other than `:oklab`, keyed by
        # name. Each takes a candidate and the background and returns a
        # score, higher is better. Extensions such as tincture-apca add to it.
        #
        #: () -> Hash[Symbol, ^(Color, Color) -> Numeric]
        def contrast_scorers
          @contrast_scorers ||= { wcag: ->(text, background) { text.contrast_ratio(background) } }
        end
      end

      # WCAG 2 relative luminance, from 0 (black) to 1 (white). Ignores
      # alpha.
      #
      #: () -> Float
      def luminance
        red, green, blue = linear_rgb
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
      end

      # WCAG 2 contrast ratio against another colour, from 1 to 21. WCAG AA
      # asks for 4.5 for body text. Ignores alpha.
      #
      #     Tincture::Color.parse("#767676").contrast_ratio("white") # => 4.54…
      #
      #: (String | Color other) -> Float
      def contrast_ratio(other)
        darker, lighter = [luminance, Color.parse(other).luminance].minmax
        (lighter + 0.05) / (darker + 0.05)
      end

      # The colour for text set on this colour, like CSS `contrast-color()`:
      # BLACK or WHITE by default, or the best of the colours given in
      # `among:`. Ties go to the earlier candidate.
      #
      # Custom `among:` candidates can return a colour that fails WCAG 2 AA,
      # even with `method: :wcag`: it picks the best candidate, not a
      # passing one. On `#0a7cff`, `among: ["#1f2937", "white"]` returns
      # white at 3.93:1. Check the result with #readable_on?, or use
      # #nearest_readable_on to adjust it.
      #
      # - `method: :wcag` (the default) picks the higher WCAG 2 contrast
      #   ratio. Between black and white that always passes AA. It picks
      #   black on bright blues, where most people would use white.
      # - `method: :apca` picks the larger APCA contrast. It needs the
      #   tincture-apca gem, whose licence restricts it to web content.
      # - `method: :oklab` picks black when Oklab lightness is above
      #   OKLAB_CONTRAST_THRESHOLD, so it only takes black and white. It
      #   needs no extra gem, and agrees with APCA on about 98% of sRGB
      #   colours, where WCAG 2 agrees on about 71%. Its pick fails WCAG 2
      #   AA on about 29% of colours, so audits flag it.
      #
      #     blue = Tincture::Color.parse("#0a7cff")
      #     blue.contrast_color                 # => BLACK
      #     blue.contrast_color(method: :oklab) # => WHITE
      #
      #     amber = Tincture::Color.parse("#ffd166")
      #     amber.contrast_color(among: ["#1f2937", "white"]).hex # => "#1f2937"
      #
      #: (?among: Array[String | Color], ?method: Symbol) -> Color
      def contrast_color(among: [BLACK, WHITE], method: :wcag)
        candidates = among.map { Color.parse(it) }

        if method == :oklab
          oklab_contrast_color(candidates)
        else
          candidates.max_by { contrast_scorer(method).call(it, self) }
        end
      end

      alias contrast_colour contrast_color

      # Whether text in this colour on `background` meets a WCAG 2 level:
      # `level: :aa` (the default) or `:aaa`, with `large: true` for text at
      # least 18pt, or 14pt bold.
      #
      #: (String | Color background, ?level: :aa | :aaa, ?large: bool) -> bool
      def readable_on?(background, level: :aa, large: false)
        contrast_ratio(background) >= WCAG_RATIOS.fetch(level).fetch(large ? :large : :normal)
      end

      # The highest WCAG 2 level text in this colour reaches on
      # `background`: `:aaa`, `:aa` (also AAA for large text), `:aa_large`,
      # or `nil`.
      #
      #: (String | Color background) -> (:aaa | :aa | :aa_large | nil)
      def contrast_level(background)
        ratio = contrast_ratio(background)

        if ratio >= WCAG_RATIOS[:aaa][:normal] then :aaa
        elsif ratio >= WCAG_RATIOS[:aa][:normal] then :aa
        elsif ratio >= WCAG_RATIOS[:aa][:large] then :aa_large
        end
      end

      # The closest colour to this one that is #readable_on? `background`:
      # this colour if it already is, otherwise this colour moved in Oklab
      # toward black or white, keeping its hue. `nil` when even black or
      # white cannot reach the level.
      #
      #     Tincture::Color.parse("#ff8800").nearest_readable_on("white").hex # => "#b66000"
      #
      #: (String | Color background, ?level: :aa | :aaa, ?large: bool) -> Color?
      def nearest_readable_on(background, level: :aa, large: false)
        background = Color.parse(background)
        extreme = background.contrast_color

        if readable_on?(background, level:, large:)
          self
        elsif extreme.readable_on?(background, level:, large:)
          nearest_mix_toward(extreme) { it.readable_on?(background, level:, large:) }
        end
      end

      private

      # The smallest mix toward `extreme` that passes the block. Assumes the
      # block fails here and passes at `extreme`.
      def nearest_mix_toward(extreme)
        amount = (0.0..1.0).bsearch { |candidate| yield mixed_toward(extreme, candidate) }
        mixed_toward(extreme, amount)
      end

      def contrast_scorer(method)
        Color.contrast_scorers.fetch(method) do
          hint = method == :apca ? ' (add the tincture-apca gem and require "tincture/apca")' : ''
          raise ArgumentError, "unknown method #{method.inspect}#{hint}"
        end
      end

      def oklab_contrast_color(candidates)
        if candidates.sort_by(&:luminance) == [BLACK, WHITE]
          oklab_components.first > OKLAB_CONTRAST_THRESHOLD ? BLACK : WHITE
        else
          raise ArgumentError, 'method: :oklab picks between black and white only'
        end
      end
    end

    include Contrast
    extend Contrast::ClassMethods
  end
end
