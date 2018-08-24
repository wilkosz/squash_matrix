# frozen_string_literal: true

RSpec.describe SquashMatrix::VERSION do
  it 'has a version number' do
    expect(SquashMatrix::VERSION).not_to be nil
  end
end

RSpec.describe SquashMatrix::Constants do
  it 'player from player path' do
    expect(SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match('/Home/Player/42546')[1]).to eq('42546')
  end

  it 'team id from team path' do
    expect(SquashMatrix::Constants::TEAM_FROM_PATH_REGEX.match('/Home/Team/1')[1]).to eq('1')
  end

  it 'match from match path' do
    expect(SquashMatrix::Constants::MATCH_FROM_PATH_REGEX.match('/Home/Match/30')[1]).to eq('30')
  end

  it 'club name from title tags <title></title>' do
    expect(SquashMatrix::Constants::CLUB_FROM_TITLE_REGEX.match('Club - Melbourne University')[1]).to eq('Melbourne University')
  end

  it 'club id from path' do
    expect(SquashMatrix::Constants::CLUB_FROM_PATH_REGEX.match('/Home/Club/336')[1]).to eq('336')
  end

  it 'too many requests from body' do
    body = 'foo foo Request made too soon. This is to prevent abuse to the site. We apologise for the inconvenience foo foo'
    expect(SquashMatrix::Constants::TOO_MANY_REQUESTS_ERROR_REGEX.match(body)).not_to be nil
  end

  it 'forbidden from body' do
    body = 'foo foo Forbidden foo foo'
    expect(SquashMatrix::Constants::FORBIDDEN_ERROR_REGEX.match(body)).not_to be nil
  end

  it 'expires from cookie regex' do
    value = 'expires=Sat, 25-Aug-2018 00:00:00 UTC'
    expect(Time.parse(SquashMatrix::Constants::EXPIRES_FROM_COOKIE_REGEX.match(value)[1])).to eq(Time.new(2018, 8, 25, 0, 0, 0, '+00:00').utc)
  end
end

RSpec.describe SquashMatrix::Client do
  # squash matrix will throw forbidden error if frequency too high
  after(:example) { puts "\s\ssleeping for 60"; sleep 60 }

  it 'creates a client' do
    c = SquashMatrix::Client.new
    expect(c.class).to eq(SquashMatrix::Client)
  end

  it 'client with bad credentials throws SquashMatrix::Errors::AuthorizationError' do
    expect { SquashMatrix::Client.new(player: 100, password: 'abc123') }.to raise_error(SquashMatrix::Errors::AuthorizationError)
  end

  it 'client throws Timeout::Error' do
    c = SquashMatrix::Client.new(timeout: 1)
    expect { c.get_player_info(1) }.to raise_error(Timeout::Error)
  end

  it 'client exceptions suppressed' do
    c = SquashMatrix::Client.new(timeout: 1, suppress_errors: true)
    expect(c.get_player_info(1)).to be nil
  end

  it 'client returns joshua wilkosz player information' do
    c = SquashMatrix::Client.new
    expect(c.get_player_info(42547)).not_to be nil
  end

  it 'client returns melbourne university club information' do
    c = SquashMatrix::Client.new
    expect(c.get_club_info(336)).not_to be nil
  end

  it 'client performs search' do
    c = SquashMatrix::Client.new
    expect(c.get_search_results('joshua')).not_to be nil
  end
end
