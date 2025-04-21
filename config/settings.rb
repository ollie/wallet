require 'logger'
require 'yaml'
require 'bigdecimal/util'

module Settings
  extend self

  def root
    @root ||= Pathname.new(File.expand_path('..', __dir__))
  end

  def environment
    @environment ||= ENV['RACK_ENV'] || 'development'
  end

  def development?
    environment == 'development'
  end

  def production?
    environment == 'production'
  end

  def privacy_mode?
    false
  end

  def load_files(path)
    Dir[root.join(path, '*.rb')].each { |file| require file }
  end

  def autoloader
    @autoloader ||= begin
      load_files('app/lib/ext/**')
      loader = Zeitwerk::Loader.new
      # loader.log!
      loader.push_dir(root.join('app'))
      loader.ignore(root.join('app/views'))
      loader.push_dir(root.join('app/lib'))
      loader.ignore(root.join('app/lib/ext'))
      loader.push_dir(root.join('app/models'))
      loader.enable_reloading if development?
      loader.setup

      if development?
        require 'listen'
        listener = Listen.to('app', 'config', only: /\.rb\z/) { loader.reload }
        listener.start
      end

      loader
    end
  end

  def database
    @database ||= begin
      # Convert all times to UTC while saving and loading.
      Sequel.default_timezone = :utc
      Sequel.connect(
        database_url,
        encoding:        'utf-8',
        logger:          (development? ? Logger.new($stdout) : nil),
        max_connections: pool_size
      ).tap do |database|
        database.extension(:connection_validator)
        database.extension(:pg_json)
        database.extension(:pg_array)
        database.extension(:pg_triggers)
      end
    end
  end

  def database_url
    @database_url ||= begin
      config = YAML.safe_load(root.join('config/database.yml').read, permitted_classes: [Symbol, Date]).fetch(environment)
      "postgres://#{config['username']}:#{config['password']}@localhost/#{config['database']}"
    end
  end

  def setup_i18n
    I18n.load_path = Dir[root.join('config/locales/**/*.{rb,yml}')]
    I18n.available_locales = [:cs]
    I18n.default_locale = :cs
  end

  def secrets
    @secrets ||= begin
      config = YAML.safe_load(root.join('config/secrets.yml').read, permitted_classes: [Symbol, Date]).fetch(environment)

      Object.new.tap do |object|
        config.each do |key, value|
          object.define_singleton_method(key) do
            value
          end
        end
      end
    end
  end

  private

  def pool_size
    @pool_size ||= (ENV['POOL_SIZE'] || 5).to_i
  end
end
