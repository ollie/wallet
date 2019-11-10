RSpec.describe 'Entries' do
  it 'root redirects to login' do
    get '/'

    expect(last_status).to eq(302)
    expect(redirect_url).to eq('/sessions/new')
  end

  it 'root redirects to entries index' do
    login
    get '/'

    expect(last_status).to eq(302)
    expect(redirect_url).to eq('/entries')
  end

  it 'index without any entries redirects to new' do
    login
    get '/entries'

    expect(last_status).to eq(302)
    expect(redirect_url).to eq('/entries/new')
  end

  it 'index' do
    Entry.create(amount: 1000, date: '2019-11-10')

    login
    get '/entries'

    expect(last_status).to eq(200)
    expect(last_body).to_not be_empty
  end
end
