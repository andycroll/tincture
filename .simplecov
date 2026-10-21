# frozen_string_literal: true

SimpleCov.configure do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100 if ENV['CI']
  cover 'lib/**/*.rb'
  skip 'lib/tincture/railtie.rb'
  skip 'lib/tincture/version.rb'
end
