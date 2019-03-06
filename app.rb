class App < Sinatra::Base
  configure do
    Settings.database
    Settings.setup_i18n
    Settings.load_files('lib/**')
    Settings.load_files('models/**')
  end

  set :slim, layout: :'layouts/application',
             pretty: true
  set :sessions, expire_after: 2.days
  set :session_secret, Settings.secrets.session_secret

  def self.Route(hash)
    route_name = hash.keys.first
    route_path = hash[route_name]

    helpers do
      define_method("#{route_name}_path") do |id = nil|
        if route_path =~ /:id/
          raise ArgumentError, "Missing :id parameter for route #{route_path}" unless id
          route_path.gsub(':id', id.to_s)
        else
          route_path
        end
      end
    end

    route_path
  end

  helpers do
    def partial_slim(template, locals = {})
      slim(template.to_sym, layout: false, locals: locals)
    end

    def title(text = nil, head: false)
      return @title = text if text
      return [@title, t('title')].compact.join(' – ') if head

      @title
    end

    def icon(filename)
      @@icon_cache ||= {}
      @@icon_cache[filename] ||= begin
        svg = Settings.root.join('public/svg/octicons', "#{filename}.svg").read
        %(<span class="octicon">#{svg}</span>)
      end
    end

    def t(key, options = nil)
      I18n.t(key, options)
    end

    def l(key, options = nil)
      if options
        I18n.l(key, **options)
      else
        I18n.l(key)
      end
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

    def this_month_date(date)
      today = Date.today
      begin
        Date.new(today.year, today.month, date.day)
      rescue ArgumentError
        Date.new(today.year, today.month, -1)
      end
    end

    def qs_tag_ids(entry)
      tag_ids = entry.tags_dataset.select_map(:id)

      return if tag_ids.empty?

      ''.tap do |s|
        s << '&'
        s << tag_ids
             .map { |tag_id| "entry[tag_ids][]=#{tag_id}" }
             .join('&')
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
        s.gsub!(' ', '&nbsp;')
      end
    end

    def formatted_date(date)
      l(date).gsub!(' ', '&nbsp;')
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

      encoded_params = serialize_qs(params)

      "?#{encoded_params}"
    end

    def serialize_qs(params)
      serialized_params = []

      params.each do |key, value|
        next if value.is_a?(Hash)
        serialized_params << "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end

      serialized_params.join('&')
    end
  end

  #######
  # Hooks
  #######

  before do
    pass if request.path == new_session_path
    pass if Login.valid?(session[:encrypted_username], session[:encrypted_password])

    redirect new_session_path
  end

  ##########
  # Sessions
  ##########

  get Route(new_session: '/sessions/new') do
    slim :'sessions/new', layout: :'layouts/sessions'
  end

  post '/sessions/new' do
    encrypted_username = Login.encrypt_username(params[:username])
    encrypted_password = Login.encrypt_password(params[:password])

    if Login.valid?(encrypted_username, encrypted_password)
      session[:encrypted_username] = encrypted_username
      session[:encrypted_password] = encrypted_password

      redirect entries_path
    else
      slim :'sessions/new', layout: :'layouts/sessions', locals: {
        login_failed: true
      }
    end
  end

  #########
  # Entries
  #########

  get '/' do
    redirect entries_path
  end

  get Route(entries: '/entries') do
    if Entry.count.zero?
      redirect new_entry_path
    else
      slim :'entries/index'
    end
  end

  get Route(expenses: '/entries/expenses.json') do
    tags = {}

    Entry.expenses.by_month(pagination_date).eager(:tags).each do |entry|
      entry.primary_tags.each do |tag|
        entries = tags[tag.name] ||= []
        entries << entry.amount
      end
    end

    sorted_tags = []

    tags
      .map { |name, entries| [name, entries.sum * -1] }
      .sort { |(_, a_sum), (_, b_sum)| b_sum <=> a_sum }
      .each { |name, sum| sorted_tags << { name: name, sum: sum } }

    MultiJson.dump(sorted_tags)
  end

  get Route(new_entry: '/entries/new') do
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
      redirect(params[:back_url] || entries_path)
    else
      slim :'entries/new', locals: {
        entry: entry
      }
    end
  end

  get Route(edit_entry: '/entries/:id/edit') do
    slim :'entries/edit', locals: {
      entry: Entry.with_pk!(params[:id])
    }
  end

  post '/entries/:id/edit' do
    entry = Entry.with_pk!(params[:id])
    entry.set_fields(params[:entry], [:amount, :date, :accounted_on, :note])

    if entry.valid?
      entry.save_and_handle_tags(params)
      redirect(params[:back_url] || entries_path)
    else
      slim :'entries/edit', locals: {
        entry: entry
      }
    end
  end

  post Route(delete_entry: '/entries/:id/delete') do
    entry = Entry.with_pk!(params[:id])
    entry.destroy
    redirect entries_path
  end

  ######
  # Tags
  ######

  get Route(tags: '/tags') do
    tags = Tag.ordered

    if tags.count.zero?
      redirect new_tag_path
    else
      slim :'tags/index', locals: {
        tags: tags
      }
    end
  end

  get Route(new_tag: '/tags/new') do
    slim :'tags/new', locals: {
      tag: Tag.new
    }
  end

  post '/tags/new' do
    tag = Tag.new
    tag.set_fields(params[:tag], [:name, :color, :primary])

    if tag.valid?
      tag.save
      redirect tags_path
    else
      slim :'tags/new', locals: {
        tag: tag
      }
    end
  end

  get Route(edit_tag: '/tags/:id/edit') do
    slim :'tags/edit', locals: {
      tag: Tag.with_pk!(params[:id])
    }
  end

  post '/tags/:id/edit' do
    tag = Tag.with_pk!(params[:id])
    tag.set_fields(params[:tag], [:name, :color, :primary])

    if tag.valid?
      tag.save
      redirect tags_path
    else
      slim :'tags/edit', locals: {
        tag: tag
      }
    end
  end

  post Route(delete_tag: '/tags/:id/delete') do
    tag = Tag.with_pk!(params[:id])
    tag.destroy
    redirect tags_path
  end

  post Route(update_tags_positions: '/tags/update_positions') do
    positions = params[:positions]

    Tag.db.transaction do
      tags = Tag.where(id: positions.keys)
      tags.each { |tag| tag.update(position: positions.fetch(tag.id.to_s)) }
    end

    halt 201
  end

  get Route(tag: '/tags/:id') do
    slim :'tags/show', locals: {
      tag: Tag.with_pk!(params[:id])
    }
  end

  ##########
  # Balances
  ##########

  get Route(balances: '/balances') do
    balances = Balance.ordered

    if balances.count.zero?
      redirect new_balance_path
    else
      slim :'balances/index', locals: {
        balances: balances
      }
    end
  end

  get Route(balances_json: '/balances.json') do
    balances = Balance.data_for_chart
    MultiJson.dump(balances)
  end

  get Route(new_balance: '/balances/new') do
    today = Date.today

    slim :'balances/new', locals: {
      balance: Balance.new(year_month: Date.today.strftime('%Y-%m'))
    }
  end

  post '/balances/new' do
    balance = Balance.new
    balance.set_fields(params[:balance], [:amount, :year_month, :note])

    if balance.valid?
      balance.save
      redirect balances_path
    else
      slim :'balances/new', locals: {
        balance: balance
      }
    end
  end

  get Route(edit_balance: '/balances/:id/edit') do
    slim :'balances/edit', locals: {
      balance: Balance.with_pk!(params[:id])
    }
  end

  post '/balances/:id/edit' do
    balance = Balance.with_pk!(params[:id])
    balance.set_fields(params[:balance], [:amount, :year_month, :note])

    if balance.valid?
      balance.save
      redirect balances_path
    else
      slim :'balances/edit', locals: {
        balance: balance
      }
    end
  end

  post Route(delete_balance: '/balances/:id/delete') do
    balance = Balance.with_pk!(params[:id])
    balance.destroy
    redirect balances_path
  end
end
