source 'https://rubygems.org'

# Sinatra is a DSL for quickly creating web applications in Ruby with minimal
# effort.
gem 'sinatra', '>= 1.4', require: 'sinatra/base'

# Slim is a template language whose goal is reduce the syntax to the essential
# parts without becoming cryptic.
gem 'slim'

# Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for
# Ruby/Rack applications. Puma is intended for use in both development and
# production environments. In order to get the best throughput, it is highly
# recommended that you use a Ruby implementation with real threads like Rubinius
# or JRuby.
gem 'puma'

# Pg is the Ruby interface to the PostgreSQL. It works with PostgreSQL 8.4 and
# later.
gem 'pg'

# The Database Toolkit for Ruby.
gem 'sequel'

# sequel_pg overwrites the inner loop of the Sequel postgres adapter row
# fetching code with a C version. The C version is significantly faster (2-6x)
# than the pure ruby version that Sequel uses by default. sequel_pg also offers
# optimized versions of some dataset methods, as well as adds support for using
# PostgreSQL streaming.
gem 'sequel_pg', require: 'sequel'

# Database enforced timestamps, immutable columns, counter/sum caches, and touch
# propogation.
gem 'sequel_postgresql_triggers'

# A common interface to multiple JSON libraries, including Oj, Yajl, the JSON
# gem (with C-extensions), the pure-Ruby JSON gem, NSJSONSerialization, gson.rb,
# JrJackson, and OkJson.
gem 'multi_json'

# The fastest JSON parser and object serializer.
gem 'oj'

# New wave Internationalization support for Ruby.
gem 'i18n'

group :development do
  # An IRB alternative and runtime developer console.
  gem 'pry', require: false

  # Pry Doc is a Pry REPL plugin. It provides extended documentation support for
  # the REPL by means of improving the `show-doc` and `show-source` commands.
  # With help of the plugin the commands are be able to display the source code
  # and the docs of Ruby methods and classes implemented in C. documentation.
  gem 'pry-doc', require: false

  # Combine 'pry' with 'byebug'. Adds 'step', 'next', 'finish', 'continue' and
  # 'break' commands to control execution.
  gem 'pry-byebug', require: false

  # Automatic Ruby code style checking tool. Aims to enforce the community-
  # driven Ruby Style Guide.
  gem 'rubocop', require: false

  # The Listen gem listens to file modifications and notifies you about the
  # changes. Works everywhere!
  gem 'listen', require: false
end
