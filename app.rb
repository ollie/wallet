require_relative 'config/settings'

# Main web application.
class App < Sinatra::Base
  set :slim, layout: :'layouts/application',
             pretty: true

  configure do
    config = YAML.safe_load(File.read("#{settings.root}/config/secrets.yml"))
    config = config.fetch(ENV['RACK_ENV'])

    set :login_encrypted_username, config.fetch('login_encrypted_username')
    set :login_encrypted_password, config.fetch('login_encrypted_password')
  end

  use Rack::Auth::Basic, 'Whee' do |username, password|
    encrypted_username = Digest::SHA256.hexdigest(username)
    encrypted_password = Digest::SHA256.hexdigest(password)

    encrypted_username == settings.login_encrypted_username &&
      encrypted_password == settings.login_encrypted_password
  end

  helpers do
    def partial_slim(template, locals = {})
      slim(template.to_sym, layout: false, locals: locals)
    end

    def t(key, options = nil)
      I18n.t(key, options)
    end

    def l(key, options = nil)
      I18n.l(key, options)
    end

    def pagination_date
      @pagination_date ||= begin
        year  = params[:year]&.to_i  || Date.today.year
        month = params[:month]&.to_i || Date.today.month

        Date.new(year, month)
      end
    end

    def previous_month
      @previous_month ||= begin
        if pagination_date.month == 1
          Date.new(pagination_date.year - 1, 12)
        else
          Date.new(pagination_date.year, pagination_date.month - 1)
        end
      end
    end

    def next_month
      return @next_month if defined?(@next_month)

      @next_month = nil
      today = Date.today

      return @next_month if pagination_date.year > today.year || pagination_date.year == today.year && pagination_date.month >= today.month

      next_month = if pagination_date.month == 12
                     Date.new(pagination_date.year + 1, 1)
                   else
                     Date.new(pagination_date.year, pagination_date.month + 1)
                   end

      @next_month = next_month
    end

    def prefilled_date(date)
      return date if date

      today = Date.today

      if pagination_date.year == today.year && pagination_date.month == today.month
        Date.today
      elsif pagination_date < today
        Date.new(pagination_date.year, pagination_date.month, -1)
      end
    end

    def formatted_amount(amount, plus: true, format: '%+.02f')
      format = '%.02f' unless plus
      format(format, amount).tap do |s|
        s.reverse!
        s.gsub!(/(\d{3})(\d)/, '\1 \2')
        s.tr!('.', ',')
        s.reverse!
        s << ' Kč'
      end
    end

    def sort_by
      sort_by = params[:sort_by]
      return if sort_by.nil? || sort_by.empty?
      sort_by.to_sym
    end

    def qs(hash)
      params = self.params.except('captures', 'splat', 'id')
      params.merge!(hash.stringify_keys)
      params.scrub!

      encoded_params =
        params
        .map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }
        .join('&')

      "?#{encoded_params}"
    end
  end

  get '/' do
    redirect '/entries'
  end

  #########
  # Entries
  #########

  get '/entries' do
    if Entry.count.zero?
      redirect '/entries/new'
    else
      slim :'entries/index'
    end
  end

  get '/entries/expenses.json' do
    tags = {}

    Entry.expenses.by_month(pagination_date).eager(:tags).each do |entry|
      entry.primary_tags.each do |tag|
        entries = tags[tag.name] ||= []
        entries << entry.amount
      end
    end

    sorted_tags = {}

    tags
      .map { |name, entries| [name, entries.sum * -1] }
      .sort { |(_, a_sum), (_, b_sum)| b_sum <=> a_sum }
      .each { |name, sum| sorted_tags[name] = sum }

    MultiJson.dump(sorted_tags)
  end

  get '/entries/new' do
    entry = Entry.new
    entry.set_fields(params[:entry] || {}, [:amount, :date, :accounted_on, :note])

    slim :'entries/new', locals: {
      entry: entry
    }
  end

  post '/entries/new' do
    entry = Entry.new
    entry.set_fields(params[:entry], [:amount, :date, :accounted_on, :note])

    if entry.valid?
      entry.save_and_handle_tags(params)
      redirect(params[:back_url] || '/entries')
    else
      slim :'entries/new', locals: {
        entry: entry
      }
    end
  end

  get '/entries/:id/edit' do
    slim :'entries/edit', locals: {
      entry: Entry.with_pk!(params[:id])
    }
  end

  post '/entries/:id/edit' do
    entry = Entry.with_pk!(params[:id])
    entry.set_fields(params[:entry], [:amount, :date, :accounted_on, :note])

    if entry.valid?
      entry.save_and_handle_tags(params)
      redirect(params[:back_url] || '/entries')
    else
      slim :'entries/edit', locals: {
        entry: entry
      }
    end
  end

  post '/entries/:id/delete' do
    entry = Entry.with_pk!(params[:id])
    entry.destroy
    redirect '/entries'
  end

  ######
  # Tags
  ######

  get '/tags' do
    tags = Tag.ordered

    if tags.count.zero?
      redirect '/tags/new'
    else
      slim :'tags/index', locals: {
        tags: tags
      }
    end
  end

  get '/tags/new' do
    slim :'tags/new', locals: {
      tag: Tag.new
    }
  end

  post '/tags/new' do
    tag = Tag.new
    tag.set_fields(params[:tag], [:name, :color, :primary])

    if tag.valid?
      tag.save
      redirect '/tags'
    else
      slim :'tags/new', locals: {
        tag: tag
      }
    end
  end

  get '/tags/:id/edit' do
    slim :'tags/edit', locals: {
      tag: Tag.with_pk!(params[:id])
    }
  end

  post '/tags/:id/edit' do
    tag = Tag.with_pk!(params[:id])
    tag.set_fields(params[:tag], [:name, :color, :primary])

    if tag.valid?
      tag.save
      redirect '/tags'
    else
      slim :'tags/edit', locals: {
        tag: tag
      }
    end
  end

  post '/tags/:id/delete' do
    tag = Tag.with_pk!(params[:id])
    tag.destroy
    redirect '/tags'
  end

  post '/tags/update_positions' do
    positions = params[:positions]

    Tag.db.transaction do
      tags = Tag.where(id: positions.keys)
      tags.each { |tag| tag.update(position: positions.fetch(tag.id.to_s)) }
    end

    halt 201
  end

  get '/tags/:id' do
    slim :'tags/show', locals: {
      tag: Tag.with_pk!(params[:id])
    }
  end

  ##########
  # Balances
  ##########

  get '/balances' do
    balances = Balance.ordered

    if balances.count.zero?
      redirect '/balances/new'
    else
      slim :'balances/index', locals: {
        balances: balances
      }
    end
  end

  get '/balances/new' do
    today = Date.today

    slim :'balances/new', locals: {
      balance: Balance.new(year_month: "#{today.year}-#{today.month}")
    }
  end

  post '/balances/new' do
    balance = Balance.new
    balance.set_fields(params[:balance], [:amount, :year_month, :note])

    if balance.valid?
      balance.save
      redirect '/balances'
    else
      slim :'balances/new', locals: {
        balance: balance
      }
    end
  end

  get '/balances/:id/edit' do
    slim :'balances/edit', locals: {
      balance: Balance.with_pk!(params[:id])
    }
  end

  post '/balances/:id/edit' do
    balance = Balance.with_pk!(params[:id])
    balance.set_fields(params[:balance], [:amount, :year_month, :note])

    if balance.valid?
      balance.save
      redirect '/balances'
    else
      slim :'balances/edit', locals: {
        balance: balance
      }
    end
  end

  post '/balances/:id/delete' do
    balance = Balance.with_pk!(params[:id])
    balance.destroy
    redirect '/balances'
  end
end
