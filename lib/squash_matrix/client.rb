require 'net/http'
require 'date'
require 'timeout'
require_relative 'constants'
require_relative 'nokogiri-parser'
require_relative 'errors'

module SquashMatrix

  # SquashMatrix::Client for http interactions with squashmatrix.com website.
  #   If authentication credentials are provided squash matrix will allow
  #   considerable more requests for an IP address and allow forbidden conent
  #   to be requested.
  class Client

    # Returns newly created SquashMatrix::Client for making club and player
    #   information requests
    # @note will return SquashMatrix::AuthorizationError if specified credentials are incorrect and squash matrix authentication returns forbidden
    # @param [Hash{:player=>Numeric,:email=>String,:suppress_errors=>TrueClass,:timeout=>Numeric}]
    # @return [SquashMatrix::Client, SquashMatrix::AuthorizationError]

    def initialize(player: nil, email: nil, password: nil, suppress_errors: false, timeout: 60)
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
        @suppress_errors = suppress_errors
        @timeout = timeout
        authenticate
      end
    end

    # Returns information from the specified player id. Example:
    #   !{event: "foo", division: "foo", round: "1", position: "1", games: "3-0", points: "33-10", rating_adjustment: "1.1", rating: "200", opponent_rating: "190", opponen_name: "foo", opponent_id: "123", match_id: "123", date: Time.now}
    # @note If suppress_errors == true return type [Hash, nil] else SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, etc...
    # @param id [Numeric] club id found on squash matrix
    # @return [Hash, nil, SquashMatrix::ForbiddenError, SquashMatrix::UnknownError] hash object containing club information

    def club_info(id=nil)
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::CLUB_PATH.gsub(':id', id.to_s)
        })
      success_proc = lambda {|res| SquashMatrix::NokogiriParser.club_info(res.body)}
      handle_http_request(uri, success_proc)
    end

    # Returns information from the specified club id. Example:
    #   !{name: "foo", players: [{rank: 1, name: "foo", id: 1, rating: 123.45}], juniors: [{rank: 1, name: "foo_junior", id: 1, rating: 123.45}]}
    # @note If suppress_errors == true return type [Hash, nil] else SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, etc...
    # @param id [Numeric] played id found on squash matrix
    # @return [Hash, nil, SquashMatrix::ForbiddenError, SquashMatrix::UnknownError] hash object containing club information

    def player_info(id=nil)
      return if id.nil?
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::PLAYER_PATH.gsub(':id', id.to_s),
        query: SquashMatrix::Constants::PLAYER_RSULTS_QUERY
        })
      success_proc = lambda {|res| SquashMatrix::NokogiriParser.player_info(res.body)}
      handle_http_request(uri, success_proc)
    end

    private

    def handle_http_request(uri, success_proc)
      begin
        Timeout.timeout(@timeout) do
          req = Net::HTTP::Get.new(uri)
          set_headers(req)
          res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
          case res
          when Net::HTTPSuccess
            return success_proc.call(res)
          when Net::HTTPConflict
            raise SquashMatrix::ForbiddenError.new(res) unless @suppress_errors
          else
            raise SquashMatrix::UnknownError.new(res) unless @suppress_errors
          end
        end
      rescue Timeout::Error => e
        raise e unless @suppress_errors
      end
    end

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
      @authenticated[:cookie] = res.response[SquashMatrix::Constants::SET_COOKIE_HEADER]
      if auth_token_from_cookie(@authenticated[:cookie])
        @authenticated[:authenticated_at] = Time.now.utc
        @authenticated[:updated_at] = Time.now.utc
        @authenticated[:valid] = true
        @authenticated[:player] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(res.response[SquashMatrix::Constants::LOCATION_HEADER])[1] if @authenticated[:email] && res.response[SquashMatrix::Constants::LOCATION_HEADER]
      elsif !@suppress_errors
        error_string = SquashMatrix::NokogiriParser.log_on_error(res.body).join(', ')
        raise SquashMatrix::AuthorizationError.new(error_string)
      end
    end

    def set_headers(req=nil)
      return unless req
      if @authenticated
        {
          Cookie: @authenticated[:cookie],
          Referer: SquashMatrix::Constants::REFERER.gsub(':id', @authenticated[:player]),
          SquashMatrix::Constants::CONTENT_TYPE_HEADER.to_sym => SquashMatrix::Constants::X_WWW__FROM_URL_ENCODED
        }.each {|key, val| req[key] = val}
      end
    end

    def auth_token_from_cookie(cookie=nil)
      return unless !cookie.nil? && !cookie.empty?
      rtn = SquashMatrix::Constants::ASPXAUTH_TOKEN_FROM_COOKIE_REGEX.match(cookie)
      rtn[1] if rtn
    end
  end
end
