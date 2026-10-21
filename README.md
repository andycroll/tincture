# Tincture

[![CI](https://github.com/andycroll/tincture/actions/workflows/ci.yml/badge.svg)](https://github.com/andycroll/tincture/actions/workflows/ci.yml)

Colour values for plain Ruby, with an optional Active Model attribute type

- Parse CSS hex, named, `rgb()`, `hsl()`, `hwb()`, `oklab()` and `oklch()` colours into one immutable value
- Convert between them, plus HSV
- Check WCAG 2 contrast, pick black or white text, and find readable brand colours
- Measure colour difference with ΔE OK or CIEDE2000
- Cast model attributes with `attribute :accent, :color`, loaded automatically in Rails

## Installation

Add this line to your Gemfile:

```ruby
gem "tincture"
```

The colour code is plain Ruby with no dependencies. In a Rails app, the attribute type and validator load when the app boots. Elsewhere, require them yourself:

```ruby
require "tincture/active_model"
```

## Colors

Parse any CSS colour, legacy or modern syntax

```ruby
Tincture::Color.parse("#ff8800")
Tincture::Color.parse("rebeccapurple")
Tincture::Color.parse("rgb(255 136 0 / 50%)")
Tincture::Color.parse("hsl(32deg 100% 50%)")
Tincture::Color.parse("hwb(32 0% 0%)")
Tincture::Color.parse("oklch(0.7442 0.1812 56.46)")
```

Anything else raises `Tincture::InvalidColor`. Colours outside sRGB clip to the nearest channel values.

Or build one

```ruby
Tincture::Color.rgb(255, 136, 0)
Tincture::Color.hsl(32, 100, 50, 0.5)
Tincture::Color.hsv(32, 100, 100)
Tincture::Color.oklch(0.7442, 0.1812, 56.46)
```

Convert it

```ruby
color.hex        # "#ff8800"
color.rgb        # [255, 136, 0]
color.hsl        # [32.0, 100.0, 50.0]
color.hsv        # [32.0, 100.0, 100.0]
color.css_rgb    # "rgb(255 136 0)"
color.css_hsl    # "hsl(32 100% 50%)"
color.css_hwb    # "hwb(32 0% 0%)"
color.css_oklch  # "oklch(0.7442 0.1812 56.46)"
```

Every output comes from the 8-bit channels, so hex round-trips through any of them.

## Contrast

Pick black or white text for a background colour

```ruby
background.contrast_color                # WCAG 2, the default
background.contrast_color(method: :apca) # APCA, needs tincture-apca
background.contrast_color(method: :oklab)
```

Each returns `Tincture::Color::BLACK` or `WHITE`, like CSS `contrast-color()`. `contrast_colour` is the UK alias. WCAG 2 always passes AA for body text, but picks black on bright blues and reds where most people would use white. APCA judges by how contrast looks. Oklab compares lightness against APCA's black/white crossover: it agrees with APCA on about 98% of colours and has no licence restriction. APCA and Oklab picks fail WCAG 2 AA on about 29% of colours, so keep the default where WCAG 2 audits apply.

Check a pairing against WCAG 2

```ruby
text.contrast_ratio("#ffffff")                     # 1 to 21
text.readable_on?("#ffffff")                       # AA, normal text
text.readable_on?("#ffffff", level: :aaa, large: true)
text.contrast_level("#ffffff")                     # :aaa, :aa, :aa_large or nil
color.luminance                                    # 0 to 1
```

Find the closest readable version of a brand colour

```ruby
Tincture::Color.parse("#ff8800").nearest_readable_on("white").hex # "#b66000"
```

It moves the colour toward black or white in Oklab, keeping its hue, and returns `nil` when no colour can reach the level.

Or pick the best of your own text colours, by WCAG 2 or APCA

```ruby
Tincture::Color.parse("#ffd166").contrast_color(among: ["#1f2937", "white"]).hex # "#1f2937"
```

> [!NOTE]
> Custom candidates can fail WCAG 2 AA, even with the default `:wcag` method: it returns the best candidate, not a passing one. On `#0a7cff`, `among: ["#1f2937", "white"]` returns white at 3.93:1. Check the result with `readable_on?`, or adjust it with `nearest_readable_on`.

## APCA

APCA contrast lives in a separate gem, `tincture-apca`, because its licence only allows web content in support of WCAG. Add it and `require "tincture/apca"` to get `apca_contrast` and `contrast_color(method: :apca)`.

## Difference

Measure how different two colours look

```ruby
color.difference("#ff8000")                      # ΔE OK, under about 0.02 is hard to see
color.difference("#ff8000", formula: :ciede2000) # ΔE00, about 1 is just visible
```

CIEDE2000 matches all 34 of Sharma's reference pairs.

## Attributes

Declare the type on any model with `ActiveModel::Attributes` or Active Record. Outside Rails, `require "tincture/active_model"` first.

```ruby
class Branding < ApplicationRecord
  attribute :accent_color, :color
end

branding.accent_color = "rgb(255 136 0)"
branding.accent_color.hex # "#ff8800"
```

Blank or unparseable input casts to `nil`. Another spelling of the same colour does not mark the attribute as changed, and queries accept any CSS form. Colours render as hex in JSON.

Store bare hex for columns that hold `ff8800`

```ruby
attribute :accent_color_hex, :color, prefix: false
```

## Validation

Reject input the type could not parse (Active Record only)

```ruby
validates :accent_color, color: true
```

Blank input passes, so add `presence: true` to require a colour. Do not pass `allow_nil` or `allow_blank`: unparseable input casts to `nil`, so they skip it.

## UK spelling

Every name has a UK alias

```ruby
Tincture::Colour.parse("#ff8800")
attribute :accent_colour, :colour
validates :accent_colour, colour: true # "is not a valid colour"
background.contrast_colour
```

`Tincture::InvalidColour` is the same class as `Tincture::InvalidColor`.

## Development

```sh
bundle install
bundle exec rake        # tests and RuboCop
bundle exec rake rdoc   # API docs in doc/
```

To release, set the version in `lib/tincture/version.rb`, date the changelog entry, commit, and push a `vX.Y.Z` tag. GitHub Actions runs the checks, publishes the gem to rubygems.org through trusted publishing, and creates a GitHub release with that changelog entry as its notes.

Comments are Markdown. Method types are inline RBS (`#: (String) -> Color`), which RDoc shows on each method.
