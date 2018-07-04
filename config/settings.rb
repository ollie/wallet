require 'logger'
require 'yaml'
require 'bigdecimal/util'

# Various global and environment-specific settings.
module Settings
  extend self

  ################
  # Public methods
  ################

  # Root of the project.
  #
  # @return [Pathname]
  def root
    @root ||= Pathname.new(File.expand_path('../..', __FILE__))
  end

  # Postgres Database.
  #
  # @return [Sequel::Postgres::Database]
  def database # rubocop:disable Metrics/MethodLength
    @database ||= begin
      # Convert all times to UTC while saving and loading.
      Sequel.default_timezone = :utc
      Sequel.connect(
        database_url,
        encoding:        'utf-8',
        logger:          (development? ? Logger.new($stdout) : nil),
        max_connections: ENV['POOL_SIZE'].to_i
      ).tap do |database|
        database.extension(:connection_validator)
        database.extension(:pg_json)
        database.extension(:pg_array)
        database.extension(:pg_triggers)
      end
    end
  end

  # URL to the Postgres database.
  #
  # @return [String]
  def database_url
    @database_url ||= begin
      config = YAML.load(File.read(root.join('config', 'database.yml'))).fetch(env)
      "postgres://#{config['username']}:#{config['password']}@localhost/#{config['database']}"
    end
  end

  # Web server URL.
  #
  # @return [String]
  def server_url
    @server_url ||= 'http://127.0.0.1:9292'
  end

  # Is this running in development?
  #
  # @return [Bool]
  def development?
    env == 'development'
  end

  # Is this running in production?
  #
  # @return [Bool]
  def production?
    env == 'production'
  end

  #################
  # Private methods
  #################

  private

  def setup_i18n
    I18n.load_path = Dir[root.join('config/locales/**/*.{rb,yml}')]
    I18n.available_locales = [:cs]
    I18n.default_locale = :cs
  end

  # Current environment.
  #
  # @return [String]
  def env
    @env ||= ENV['RACK_ENV']
  end

  def global
    yield
  end

  def load_file(path)
    require root.join(path)
  end

  def load_files(path)
    Dir[root.join(path, '*.rb')].each { |file| require file }
  end

  global do
    database # Connect database before models are loaded.
    setup_i18n
    load_files('lib/core_ext')
    load_files('models')
  end
end
