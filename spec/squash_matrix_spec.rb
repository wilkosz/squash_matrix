RSpec.describe SquashMatrix do
  it "has a version number" do
    expect(SquashMatrix::VERSION).not_to be nil
  end

  it "player from player path" do
    expect(SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match("/Home/Player/42546")[1]).to eq("42546")
  end

  it "match from match path" do
    expect(SquashMatrix::Constants::MATCH_FROM_PATH_REGEX.match("/Home/Match/30")[1]).to eq("30")
  end

  it "club from title tags <title></title>" do
    expect(SquashMatrix::Constants::CLUB_FROM_TITLE_REGEX.match("Club - Melbourne University")[1]).to eq("Melbourne University")
  end

  # it "aspxauth token from cookie" do
  #   cookie = ""
  #   check = ""
  #   expect(SquashMatrix::Constants::ASPXAUTH_TOKEN_FROM_COOKIE_REGEX.match(cookie)[1]).to eq(check)
  # end

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

  if "client returns joshua wilkosz player information" do
    c = SquashMatrix::Client.new
    expect(c.player_info(42547)).not_to be nil
  end

  if "client returns melbourne university club information" do
    c = SquashMatrix::Client.new
    expect(c.club_info(42547)).not_to be nil
  end
end
