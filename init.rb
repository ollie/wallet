require 'bundler'

ENV['RACK_ENV']  ||= 'development'
ENV['POOL_SIZE'] ||= ENV['PUMA_MAX_THREADS'] || '5'

Bundler.require(:default, :web, ENV['RACK_ENV'])

require_relative 'config/settings'
require_relative 'app'
