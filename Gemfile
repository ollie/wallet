source 'https://rubygems.org'

gem 'i18n'
gem 'multi_json'
gem 'oj'
gem 'pg'
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'sequel_postgresql_triggers'

# Modes

group :web do
  gem 'sinatra', require: 'sinatra/base'
  # gem 'sinatra-flash'
  gem 'slim'
end

# Environments

group :development do
  gem 'capistrano-bundler', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rbenv', require: false
  gem 'listen', require: false # assets
  gem 'rubocop', require: false
  gem 'pry', require: false
  gem 'pry-byebug', require: false
  gem 'pry-doc', require: false
  gem 'puma', require: false
end
