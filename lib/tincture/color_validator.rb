# frozen_string_literal: true

module ActiveModel # :nodoc:
  module Validations # :nodoc:
    # `validates :accent, color: true` adds an error when a `:color` attribute
    # was given input it could not parse. The type casts that input to `nil`,
    # so this reads the raw value back, which only Active Record keeps.
    #
    # Blank input passes; pair with `presence: true` to require a colour. Do
    # not pass `allow_nil` or `allow_blank`: unparseable input casts to `nil`,
    # so they would skip it.
    class ColorValidator < EachValidator
      # The error message unless the validation passes `message:`.
      MESSAGE = 'is not a valid color'

      def validate_each(record, attribute, value) # :nodoc:
        if value.nil? && record.read_attribute_before_type_cast(attribute).present?
          record.errors.add(attribute, :invalid_color, message: options.fetch(:message, self.class::MESSAGE))
        end
      end
    end

    # `validates :accent, colour: true`, with the error in UK spelling.
    class ColourValidator < ColorValidator
      MESSAGE = 'is not a valid colour' # :nodoc:
    end
  end
end
