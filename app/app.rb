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
    privacy_mode = session[:privacy_mode]

    Settings.define_singleton_method(:privacy_mode?) do
      privacy_mode == 'true'
    end

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
    data = Charts::ExpensesByTagChart.new(pagination_date).data
    MultiJson.dump(data)
  end

  get Route(burndown_json: '/entries/burndown.json') do
    data = Charts::BurndownChart.new(pagination_date, previous_month).data
    MultiJson.dump(data)
  end

  get Route(new_entry: '/entries/new') do
    entry = Entry.new
    entry.set_fields(params[:entry] || {}, %i[amount date accounted_on note])

    slim :'entries/new', locals: {
      entry: entry
    }
  end

  post '/entries/new' do
    entry = Entry.new
    entry.set_fields(params[:entry], %i[amount date accounted_on note tag_ids])

    if entry.valid?
      entry.save_and_handle_tags
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
    entry_for_duplication = Entry.with_pk!(params[:id])
    entry = Entry.new_from_entry(entry_for_duplication)

    slim :'entries/new', locals: {
      entry: entry
    }
  end

  get Route(new_entry_from_recurring: '/entries/new_recurring') do
    recurring_entry = RecurringEntry.with_pk!(params[:recurring_entry_id])
    entry = Entry.new_from_recurring_entry(recurring_entry)

    slim :'entries/new', locals: {
      entry: entry
    }
  end

  post '/entries/:id/edit' do
    entry = Entry.with_pk!(params[:id])
    entry.set_fields(params[:entry], %i[amount date accounted_on note tag_ids])

    if entry.valid?
      entry.save_and_handle_tags
      redirect(entries_path(entry_year_month_qs_params(entry)))
    else
      slim :'entries/edit', locals: {
        entry: entry
      }
    end
  end

  get Route(mark_entry_as_accounted_on_today: '/entries/:id/mark_as_accounted_on_today') do
    entry = Entry.with_pk!(params[:id])
    entry.mark_as_accounted_on(Date.today) unless entry.accounted_on
    redirect(entries_path(entry_year_month_qs_params(entry)))
  end

  get Route(mark_entry_as_accounted_on_yesterday: '/entries/:id/mark_as_accounted_on_yesterday') do
    entry = Entry.with_pk!(params[:id])
    entry.mark_as_accounted_on(Date.today - 1) unless entry.accounted_on
    redirect(entries_path(entry_year_month_qs_params(entry)))
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

  get Route(tags_report: '/tags/report') do
    slim :'tags/report', locals: {
      report: TagsReport.new
    }
  end

  get Route(new_tag: '/tags/new') do
    slim :'tags/new', locals: {
      tag: Tag.new
    }
  end

  post '/tags/new' do
    tag = Tag.new
    tag.set_fields(params[:tag], %i[name icon color primary])

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
    tag.set_fields(params[:tag], %i[name icon color primary])

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
    data = Charts::TagEntriesChart.new(tag_id: params[:id], date: pagination_date).data
    MultiJson.dump(data)
  end

  ##################
  # Tag combinations
  ##################

  get Route(tag_combinations: '/tag_combinations') do
    tag_combinations = TagCombination.ordered

    if tag_combinations.count.zero?
      redirect new_tag_combination_path
    else
      slim :'tag_combinations/index', locals: {
        tag_combinations: tag_combinations
      }
    end
  end

  get Route(new_tag_combination: '/tag_combinations/new') do
    slim :'tag_combinations/new', locals: {
      tag_combination: TagCombination.new
    }
  end

  post '/tag_combinations/new' do
    tag_combination = TagCombination.new
    tag_combination.set_fields((params[:tag_combination] || {}), %i[tag_ids])

    if tag_combination.valid?
      tag_combination.save
      redirect tag_combinations_path
    else
      slim :'tag_combinations/new', locals: {
        tag_combination: tag_combination
      }
    end
  end

  get Route(edit_tag_combination: '/tag_combinations/:id/edit') do
    slim :'tag_combinations/edit', locals: {
      tag_combination: TagCombination.with_pk!(params[:id])
    }
  end

  post '/tag_combinations/:id/edit' do
    tag_combination = TagCombination.with_pk!(params[:id])
    tag_combination.set_fields((params[:tag_combination] || {}), %i[tag_ids])

    if tag_combination.valid?
      tag_combination.save
      redirect tag_combinations_path
    else
      slim :'tag_combinations/edit', locals: {
        tag_combination: tag_combination
      }
    end
  end

  post Route(delete_tag_combination: '/tag_combinations/:id/delete') do
    tag_combination = TagCombination.with_pk!(params[:id])
    tag_combination.destroy
    redirect tag_combinations_path
  end

  post Route(update_tag_combinations_positions: '/tag_combinations/update_positions') do
    positions = params[:positions]

    TagCombination.db.transaction do
      tag_combinations = TagCombination.where(id: positions.keys)
      tag_combinations.each { |tag_combination| tag_combination.update(position: positions.fetch(tag_combination.id.to_s)) }
    end

    halt 201
  end

  ##########
  # Balances
  ##########

  get Route(balances: '/balances') do
    balances = Balance.ordered.paginate(params[:page], per_page: 12)

    if balances.count.zero?
      redirect new_balance_path
    else
      slim :'balances/index', locals: {
        balances: balances
      }
    end
  end

  get Route(balances_json: '/balances.json') do
    balances = Charts::BalancesChart.new.data
    MultiJson.dump(balances)
  end

  get Route(new_balance: '/balances/new') do
    slim :'balances/new', locals: {
      balance: Balance.new(year_month: Date.today.strftime('%Y-%m'))
    }
  end

  post '/balances/new' do
    balance = Balance.new
    balance.set_fields(params[:balance], %i[amount target_amount year_month note])

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
    balance.set_fields(params[:balance], %i[amount target_amount year_month note])

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
      search: Search.new(query: params[:q], date_from: params[:date_from], date_to: params[:date_to], page: params[:page])
    }
  end

  ###################
  # Recurring entries
  ###################

  get Route(recurring_entries: '/recurring_entries') do
    recurring_entries = RecurringEntry.ordered

    if recurring_entries.count.zero?
      redirect new_recurring_entry_path
    else
      slim :'recurring_entries/index', locals: {
        recurring_entries: recurring_entries
      }
    end
  end

  get Route(new_recurring_entry: '/recurring_entries/new') do
    slim :'recurring_entries/new', locals: {
      recurring_entry: RecurringEntry.new
    }
  end

  get Route(new_recurring_entry_from_entry: '/recurring_entries/new_from_entry') do
    entry = Entry.with_pk!(params[:entry_id])
    recurring_entry = RecurringEntry.new_from_entry(entry)

    slim :'recurring_entries/new', locals: {
      recurring_entry: recurring_entry
    }
  end

  post '/recurring_entries/new' do
    recurring_entry = RecurringEntry.new
    recurring_entry.set_fields(params[:recurring_entry], %i[name enabled amount months_period starts_on ends_on note tag_ids])

    if recurring_entry.valid?
      recurring_entry.save
      redirect recurring_entries_path
    else
      slim :'recurring_entries/new', locals: {
        recurring_entry: recurring_entry
      }
    end
  end

  get Route(edit_recurring_entry: '/recurring_entries/:id/edit') do
    slim :'recurring_entries/edit', locals: {
      recurring_entry: RecurringEntry.with_pk!(params[:id])
    }
  end

  post '/recurring_entries/:id/edit' do
    recurring_entry = RecurringEntry.with_pk!(params[:id])
    recurring_entry.set_fields(params[:recurring_entry], %i[name enabled amount months_period starts_on ends_on note tag_ids])

    if recurring_entry.valid?
      recurring_entry.save
      redirect recurring_entries_path
    else
      slim :'recurring_entries/edit', locals: {
        recurring_entry: recurring_entry
      }
    end
  end

  post Route(delete_recurring_entry: '/recurring_entries/:id/delete') do
    recurring_entry = RecurringEntry.with_pk!(params[:id])
    recurring_entry.destroy
    redirect recurring_entries_path
  end

  # ############
  # Privacy mode
  # ############
  get Route(toggle_privacy_mode: '/privacy_mode/toggle') do
    if session[:privacy_mode] == 'true'
      session.delete(:privacy_mode)
    else
      session[:privacy_mode] = 'true'
    end

    redirect entries_path
  end
end
