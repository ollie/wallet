require 'bundler/setup'
ENV['RACK_ENV']  ||= 'development'
ENV['POOL_SIZE'] ||= '1'

# Load settings, models and everything.
task :environment do
  Bundler.require(:default, ENV['RACK_ENV'])
  require_relative 'config/settings'
end

Dir['./tasks/*.rake'].each { |task| import task }
