# Changelog

## Unreleased

- Performance: `require "tincture"` is about 5 times faster, 10 ms down to 2 ms. Named colours now live in a Ruby hash, so loading the gem no longer loads YAML.

## 1.0.0 (2026-10-21)

- `Tincture::Color` parses CSS hex, named, `rgb()`, `hsl()`, `hwb()`, `oklab()` and `oklch()` colours, and converts between them and HSV.
- WCAG 2 contrast: `contrast_ratio`, `readable_on?`, `contrast_level`, `contrast_color` and `nearest_readable_on`.
- Colour difference with ΔE OK and CIEDE2000.
- An optional Active Model `:color` attribute type and `color:` validator, loaded automatically in Rails.
- UK spelling aliases for every name.
