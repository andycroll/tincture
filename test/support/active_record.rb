# frozen_string_literal: true

require 'active_record'
require 'tincture/active_model'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
