source 'https://rubygems.org'

gem 'i18n'
gem 'multi_json'
gem 'oj'
gem 'pg'
gem 'pry', require: false
gem 'rake', require: false
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'sequel_postgresql_triggers'
gem 'zeitwerk'

# Modes

group :web do
  gem 'sinatra', require: 'sinatra/base'
  gem 'slim'
end

# Environments

group :development do
  gem 'capistrano-bundler', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rbenv', require: false
  gem 'ed25519', require: false      # Required for Capistrano to work with ed25519 key.
  gem 'bcrypt_pbkdf', require: false # Required for Capistrano to work with ed25519 key.
  gem 'listen', require: false # assets
  gem 'pry-byebug', require: false
  gem 'pry-doc', require: false
  gem 'puma', require: false
  gem 'rubocop', require: false
end

group :test do
  # gem 'database_cleaner' # It needs ActiveRecord :(
  gem 'rack-test'
  gem 'rspec'
  gem 'simplecov'
end
