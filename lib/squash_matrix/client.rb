require 'net/http'
require 'date'
require 'timeout'
require_relative 'constants'
require_relative 'nokogiri-parser'
require_relative 'errors'

module SquashMatrix

  # Client for http interactions with squashmatrix.com website.
  # If authentication credentials are provided squash matrix will allow
  # considerably more requests for an IP address and allow forbidden conent
  # to be requested.

  class Client

    # Returns newly created Client for making club and player requests
    # @note If suppress_errors == false SquashMatrix::Errors::AuthorizationError will be raised if specified credentials are incorrect and squash matrix authentication returns forbidden
    # @param [Hash] opts the options to create client
    # @return [Client]

    def initialize(player: nil, email: nil, password: nil, suppress_errors: false, timeout: 60)
      @suppress_errors = suppress_errors
      @timeout = timeout
      if ![player || email, password].any?(&:nil?)
        @authenticated = {
          valid: false,
          authenticated_at: nil,
          updated_at: nil,
          cookie: nil,
          player: player,
          email: email,
          password: password
        }
        authenticate
      end
    end

    # Returns club information.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Numeric] club id found on squash matrix
    # @return [Hash] hash object containing club information

    def club_info(id=nil)
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::CLUB_PATH.gsub(':id', id.to_s)
        })
      success_proc = lambda {|res| SquashMatrix::NokogiriParser.club_info(res.body)}
      handle_http_request(uri, success_proc)
    end

    # Returns player information.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Numeric] played id found on squash matrix
    # @return [Hash] hash object containing player information

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

    # Returns search results
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param query [String] search query
    # @return [Hash] hash object containing search results

    def search(query=nil, squash_only: false, racquetball_only: false)
      return if query.nil? || query.empty?
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::SEARCH_PATH})
      query_params = {
        Criteria: query,
        SquashOnly: false,
        RacquetballOnly: false}
      success_proc = lambda {|res| SquashMatrix::NokogiriParser.search_results(res.body)}
      handle_http_request(uri, success_proc,
        {
          is_get_request: false,
          query_params: query_params
        })
    end

    private

    def handle_http_request(uri, success_proc, is_get_request: true, query_params: nil, headers: nil)
      begin
        Timeout.timeout(@timeout) do
          if is_get_request
            req = Net::HTTP::Get.new(uri)
            set_headers(req, headers: headers)
            res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
          else
            res = Net::HTTP.post_form(uri, query_params)
          end
          case res
          when Net::HTTPSuccess
            return success_proc && success_proc.call(res) || res
          when Net::HTTPConflict
            raise SquashMatrix::Errors::ForbiddenError.new(res) unless @suppress_errors
          else
            raise SquashMatrix::Errors::UnknownError.new(res) unless @suppress_errors
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
      headers = {
        SquashMatrix::Constants::CONTENT_TYPE_HEADER.to_sym => SquashMatrix::Constants::X_WWW__FROM_URL_ENCODED
      }
      query_params = {
        UserName: @authenticated[:player] || @authenticated[:email],
        Password: @authenticated[:password],
        RememberMe: false
      }
      res = handle_http_request(uri, nil,
        {
          is_get_request: false,
          query_params: query_params,
          headers: headers
        })
      return unless res
      @authenticated[:cookie] = res.response[SquashMatrix::Constants::SET_COOKIE_HEADER]
      if auth_token_from_cookie(@authenticated[:cookie])
        @authenticated[:authenticated_at] = Time.now.utc
        @authenticated[:updated_at] = Time.now.utc
        @authenticated[:valid] = true
        @authenticated[:player] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(res.response[SquashMatrix::Constants::LOCATION_HEADER])[1] if @authenticated[:email] && res.response[SquashMatrix::Constants::LOCATION_HEADER]
      elsif !@suppress_errors
        error_string = SquashMatrix::NokogiriParser.log_on_error(res.body).join(', ')
        raise SquashMatrix::Errors::AuthorizationError.new(error_string)
      end
    end

    def set_headers(req=nil, headers: nil)
      return unless req
      headers_to_add = {}
      headers_to_add.merge(headers) if headers
      headers_to_add.merge({
        Cookie: @authenticated[:cookie],
        Referer: SquashMatrix::Constants::REFERER.gsub(':id', @authenticated[:player]),
      }) if @authenticated
      headers_to_add.each {|key, val| req[key] = val}
    end

    def auth_token_from_cookie(cookie=nil)
      return unless !cookie.nil? && !cookie.empty?
      rtn = SquashMatrix::Constants::ASPXAUTH_TOKEN_FROM_COOKIE_REGEX.match(cookie)
      rtn[1] if rtn
    end
  end
end
