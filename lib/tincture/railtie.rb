# frozen_string_literal: true

module Tincture
  # Loads the Active Model integration when a Rails app boots, before the
  # app's own initializers and models.
  class Railtie < Rails::Railtie
    initializer 'tincture.active_model' do
      require 'tincture/active_model'
    end
  end
end
