# frozen_string_literal: true

# The Active Model integration: the `:color` and `:colour` attribute types and
# the `color:` and `colour:` validators. Rails apps load it when they boot;
# elsewhere, `require "tincture/active_model"`.

require 'active_model'
require 'tincture'
require_relative 'type'
require_relative 'color_validator'

ActiveModel::Type.register(:color, Tincture::Type)
ActiveModel::Type.register(:colour, Tincture::Type)

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Type.register(:color, Tincture::Type)
  ActiveRecord::Type.register(:colour, Tincture::Type)
end
