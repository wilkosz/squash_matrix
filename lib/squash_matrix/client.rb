require 'nokogiri'
require 'net/http'
require 'date'
require_relative 'constants'

module SquashMatrix
  class Client
    def initialize(player="42547", password="")
      if ![player, password].any? {|x| x.nil? || x.empty?}
        @authenticated = {
          valid: false,
          authenticated_at: nil,
          updated_at: nil,
          cookie: nil,
          player: player,
          password: password
        }
        authenticate
      end
    end

    def authenticate
      return unless @authenticated
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::LOGIN_PATH})
      res = Net::HTTP.post_form(
        uri,
        Player: @authenticated[:player],
        Password: @authenticated[:password])
      @authenticated[:cookie] = res.response['set-cookie']
      if !@authenticated[:cookie].empty?
        @authenticated[:authenticated_at] = Time.now.utc
        @authenticated[:updated_at] = Time.now.utc
        @authenticated[:valid] = true
      end
    end

    def group_info(id)
    end

    def event_info(id)
    end

    def division_info(id)
    end

    def team_info(id)
    end

    def player_info(id)
      return if id.nil? || id.empty?
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::PLAYER_PATH.gsub(':id', id),
        query: SquashMatrix::Constants::PLAYER_RSULTS_QUERY
        })
      req = Net::HTTP::Get.new(uri)
      if @authenticated
        {
          Cookie: @authenticated[:cookie],
          Referer: "Home/Player/#{@authenticated[:player]}",
          'Content-Type'.to_sym => 'application/x-www-form-urlencoded'
        }.each {|key, val| req[key] = val}
      end
      res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
      authenticated_update
      return unless res.is_a?(Net::HTTPSuccess) # TODO handle error
      Nokogiri::HTML(res.body)&.xpath('//table[@id="results"]//tbody//tr')&.map do |r|
        date = r.at_css('td[1]')&.content
        opponent_id = r.at_css('td[10]//a')&.attribute('href')&.content
        match_id = r.at_css('td[12]//a')&.attribute('href')&.content
        rtn = {
          event: r.at_css('td[2]')&.content,
          division: r.at_css('td[3]')&.content,
          round: r.at_css('td[4]')&.content,
          position: r.at_css('td[5]')&.content,
          games: r.at_css('td[6]')&.content,
          points: r.at_css('td[7]')&.content,
          rating_adjustment: r.at_css('td[8]')&.content,
          rating: r.at_css('td[9]')&.content,
          opponent_rating: r.at_css('td[11]')&.content
        }
        rtn[:date] = Date.parse(date) if date
        rtn[:opponent_id] = /\/Home\/Player\/(.*)/.match(opponent_id)[1] if opponent_id
        rtn[:match_id] = /\/Home\/Match\/(.*)/.match(match_id)[1] if match_id
        rtn.values.any?(&:nil?) ? nil : rtn
      end.compact
    end

    def get_club(id)
    end

    private

    def authenticated_update
      if @authenticated
        @authenticated[:updated_at] = Time.now.utc
      end
    end
  end
end
