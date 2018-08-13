RSpec.describe SquashMatrix::VERSION do
  it "has a version number" do
    expect(SquashMatrix::VERSION).not_to be nil
  end
end

RSpec.describe SquashMatrix::Constants do
  it "player from player path" do
    expect(SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match("/Home/Player/42546")[1]).to eq("42546")
  end

  it "team id from team path" do
    expect(SquashMatrix::Constants::TEAM_FROM_PATH_REGEX.match("/Home/Team/1")[1]).to eq("1")
  end

  it "match from match path" do
    expect(SquashMatrix::Constants::MATCH_FROM_PATH_REGEX.match("/Home/Match/30")[1]).to eq("30")
  end

  it "club name from title tags <title></title>" do
    expect(SquashMatrix::Constants::CLUB_FROM_TITLE_REGEX.match("Club - Melbourne University")[1]).to eq("Melbourne University")
  end

  it "club id from path" do
    expect(SquashMatrix::Constants::CLUB_FROM_PATH_REGEX.match("/Home/Club/336")[1]).to eq("336")
  end

  it "aspxauth token from cookie" do
    cookie = ".ASPXAUTH=14BBCF9EF41759D354A776C8AE678A9BC0F6D3F390FD830B00D17456AB8361CB0ADD72C570AD1B9AC0B16174BDA0AD6B9085F573F5ED45D023223B9841A43991FFD72B3D14D351B4A5CBEE35359F98C72866B81BA1A1C902103D7F939B1517B7; expires=Sun, 12-Aug-2018 23:28:54 GMT; path=/; HttpOnly"
    check = "14BBCF9EF41759D354A776C8AE678A9BC0F6D3F390FD830B00D17456AB8361CB0ADD72C570AD1B9AC0B16174BDA0AD6B9085F573F5ED45D023223B9841A43991FFD72B3D14D351B4A5CBEE35359F98C72866B81BA1A1C902103D7F939B1517B7"
    expect(SquashMatrix::Constants::ASPXAUTH_TOKEN_FROM_COOKIE_REGEX.match(cookie)[1]).to eq(check)
  end
end

RSpec.describe SquashMatrix::Client do
  # squash matrix will throw forbidden error if frequency too high
  after(:example) { puts "sleeping for 30"; sleep 30 }

  it "creates a client" do
    c = SquashMatrix::Client.new
    expect(c.class).to eq(SquashMatrix::Client)
  end

  it "client with bad credentials throws SquashMatrix::Errors::AuthorizationError" do
    expect {SquashMatrix::Client.new(player: 100, password: "abc123")}.to raise_error(SquashMatrix::Errors::AuthorizationError)
  end

  it "client throws Timeout::Error" do
    c = SquashMatrix::Client.new(timeout: 1)
    expect {c.player_info(1)}.to raise_error(Timeout::Error)
  end

  it "client exceptions suppressed" do
    c = SquashMatrix::Client.new(timeout: 1, suppress_errors: true)
    expect(c.player_info(1)).to be nil
  end

  it "client returns joshua wilkosz player information" do
    c = SquashMatrix::Client.new
    expect(c.player_info(42547)).not_to be nil
  end

  it "client returns melbourne university club information" do
    c = SquashMatrix::Client.new
    expect(c.club_info(336)).not_to be nil
  end
end
