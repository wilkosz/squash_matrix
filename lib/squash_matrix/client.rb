require 'net/http'
require 'date'
require_relative 'constants'
require_relative 'nokogiri-parser'
require_relative 'errors'

module SquashMatrix
  class Client
    def initialize(player=nil, email=nil, password=nil, suppress_errors: false)
      if ![player || email, password].any? {|x| x.nil? || x.empty?}
        @authenticated = {
          valid: false,
          authenticated_at: nil,
          updated_at: nil,
          cookie: nil,
          player: player,
          email: email,
          password: password
        }
        @suppress_errors = suppress_errors if suppress_errors
        authenticate
      end
    end

    def group_info(id=nil)
    end

    def event_info(id=nil)
    end

    def division_info(id=nil)
    end

    def team_info(id=nil)
    end

    def player_info(id=nil)
      return if id.nil? || id.empty? || !@authenticated[:player]
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::PLAYER_PATH.gsub(':id', id || @authenticated[:player]),
        query: SquashMatrix::Constants::PLAYER_RSULTS_QUERY
        })
      req = Net::HTTP::Get.new(uri)
      set_headers(req)
      res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
      return unless res.is_a?(Net::HTTPSuccess) # TODO handle error
      SquashMatrix::NokogiriParser.player_info(res.body)
    end

    def club_info(id=nil)
    end

    private

    def authenticate
      return unless @authenticated
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::LOGIN_PATH})
      res = Net::HTTP.post_form(
        uri,
        UserName: @authenticated[:player] || @authenticated[:email],
        Password: @authenticated[:password],
        RememberMe: false)
      @authenticated[:cookie] = res.response['set-cookie']
      if auth_token_from_cookie(@authenticated[:cookie])
        @authenticated[:authenticated_at] = Time.now.utc
        @authenticated[:updated_at] = Time.now.utc
        @authenticated[:valid] = true
        @authenticated[:player] = /\/Home\/Player\/(.*)/.match(res.response['location'])[1] if @authenticated[:email] && res.response['location']
      else
        error_string = SquashMatrix::NokogiriParser.log_on_error(res.body).join(', ')
        raise SquashMatrix::AuthorizationError.new(error_string) unless @suppress_errors
      end
    end

    def set_headers(req=nil)
      return unless req
      if @authenticated
        {
          Cookie: @authenticated[:cookie],
          Referer: "Home/Player/#{@authenticated[:player]}",
          'Content-Type'.to_sym => 'application/x-www-form-urlencoded'
        }.each {|key, val| req[key] = val}
      end
    end

    def auth_token_from_cookie(cookie=nil)
      return unless !cookie.nil? && !cookie.empty?
      rtn = /.ASPXAUTH=(.*);/.match(cookie)
      rtn[1] if rtn
    end
  end
end
