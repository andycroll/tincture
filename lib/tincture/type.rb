# frozen_string_literal: true

module Tincture
  # The `:color` (and `:colour`) attribute type. Casts input to a Color, and
  # blank or unparseable input to `nil`.
  #
  # Stores `"#ff8800"`, or `"ff8800"` with `prefix: false`:
  #
  #     attribute :accent_color_hex, :color, prefix: false
  class Type < ActiveModel::Type::Value
    # `prefix: false` stores hex without the leading `#`.
    #
    #: (?prefix: bool, **untyped) -> void
    def initialize(prefix: true, **)
      @prefix = prefix
      super(**)
    end

    def type = :color # :nodoc:

    # The hex string to store, or `nil` for blank or unparseable input.
    #
    #: (untyped value) -> String?
    def serialize(value)
      hex = cast(value)&.hex
      @prefix ? hex : hex&.delete_prefix('#')
    end

    private

    def cast_value(value)
      Color.parse(value)
    rescue InvalidColor
      nil
    end
  end
end
