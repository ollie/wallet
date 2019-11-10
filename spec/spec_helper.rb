require 'bundler'

ENV['RACK_ENV'] = 'test'
Bundler.require(:default, :web, ENV['RACK_ENV'])

# Coverage tool, needs to be started as soon as possible
SimpleCov.start do
  add_filter '/spec/' # Ignore spec directory
end

require_relative '../config/settings'
Settings.autoloader
Settings.database
Settings.setup_i18n

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.disable_monkey_patching!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  def app
    App
  end

  def login
    encrypted_username = Login.encrypt_username('test')
    encrypted_password = Login.encrypt_password('test')
    env('rack.session', encrypted_username: encrypted_username, encrypted_password: encrypted_password)
  end

  def last_status
    last_response.status
  end

  def last_body
    last_response.body
  end

  def redirect_url
    url = URI(last_response.header['Location'])
    url.path
  end
end
