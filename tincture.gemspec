# frozen_string_literal: true

require_relative 'lib/tincture/version'

Gem::Specification.new do |spec|
  spec.name = 'tincture'
  spec.version = Tincture::VERSION
  spec.authors = ['Andy Croll']
  spec.email = ['andy@goodscary.com']

  spec.summary = 'Colour values for Ruby, with an optional Active Model attribute type'
  spec.description = 'Parse hex, rgb() and hsl() colours into one value object, convert ' \
                     'between them, and cast model attributes to it with `attribute :accent, :color`.'
  spec.homepage = 'https://github.com/andycroll/tincture'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir['{lib}/**/*', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  end

  spec.require_paths = ['lib']
end
