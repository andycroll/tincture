# Changelog

## 1.1.0 (2026-10-21)

- Performance: `require "tincture"` is about 5 times faster, 10 ms down to 2 ms. Named colours now live in a Ruby hash, so loading the gem no longer loads YAML.
- Performance: `luminance`, `contrast_ratio`, `contrast_color` and `difference` are 15–50% faster. They look up each channel's linear value in a table and no longer compute a power. Results are unchanged.
- Performance: parsing a hex colour is about 30% faster, and `hex` (so also `to_s`, `as_json` and saving a `:color` attribute) is about twice as fast.
- Performance: `nearest_readable_on` is about 6 times faster, 224 µs down to 37 µs. It converts the colour and black or white to Oklab once per search, not on every step, and it searches 2¹⁶ steps toward black or white rather than every float. About 0.4% of results now land one 8-bit step further from the original colour. They still pass.

## 1.0.0 (2026-10-21)

- `Tincture::Color` parses CSS hex, named, `rgb()`, `hsl()`, `hwb()`, `oklab()` and `oklch()` colours, and converts between them and HSV.
- WCAG 2 contrast: `contrast_ratio`, `readable_on?`, `contrast_level`, `contrast_color` and `nearest_readable_on`.
- Colour difference with ΔE OK and CIEDE2000.
- An optional Active Model `:color` attribute type and `color:` validator, loaded automatically in Rails.
- UK spelling aliases for every name.
