class App < Sinatra::Base
  configure do
    Settings.database
    Settings.setup_i18n
  end

  set :public_folder, Settings.root.join('public')
  set :slim, layout: :'layouts/application',
             pretty: true
  set :sessions, expire_after: 2.days
  set :session_secret, Settings.secrets.session_secret

  register Sinatra::Routing
  helpers Sinatra::CommonHelpers
  helpers Sinatra::AppHelpers

  #######
  # Hooks
  #######

  before do
    Settings.autoloader.reload if Settings.development?

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

  get Route(expenses_json: '/entries/expenses.json') do
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
      redirect(entries_path(entry_year_month_qs_params(entry)))
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

  get Route(duplicate_entry: '/entries/:id/duplicate') do
    entry = Entry.with_pk!(params[:id])
    entry.prepare_for_duplication

    slim :'entries/new', locals: {
      entry: entry
    }
  end

  post '/entries/:id/edit' do
    entry = Entry.with_pk!(params[:id])
    entry.set_fields(params[:entry], [:amount, :date, :accounted_on, :note])

    if entry.valid?
      entry.save_and_handle_tags(params)
      redirect(entries_path(entry_year_month_qs_params(entry)))
    else
      slim :'entries/edit', locals: {
        entry: entry
      }
    end
  end

  post Route(delete_entry: '/entries/:id/delete') do
    entry = Entry.with_pk!(params[:id])
    entry.destroy
    redirect entries_path(entry_year_month_qs_params(entry))
  end

  ##########
  # Calendar
  ##########

  get Route(calendar: '/calendar') do
    slim :'calendar/index'
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
      redirect tag_path(tag.id)
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

  get Route(tag_entries_json: '/tags/:id/entries.json') do
    data = Tag.data_for_chart(tag_id: params[:id], date: pagination_date)
    MultiJson.dump(data)
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

  ########
  # Search
  ########

  get Route(search: '/search') do
    slim :'search/new', locals: {
      search: Search.new
    }
  end

  get Route(search_results: '/search/results') do
    slim :'search/results', locals: {
      search: Search.new(params[:q])
    }
  end
end
