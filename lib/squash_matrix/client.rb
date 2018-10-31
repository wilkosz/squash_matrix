# frozen_string_literal: true

require 'net/http'
require 'date'
require 'timeout'
require 'http-cookie'
require 'user_agent_randomizer'
require_relative 'constants'
require_relative 'nokogiri-parser'
require_relative 'errors'

module SquashMatrix
  # Client for retrieving player and club information from squashmatrix.com.
  # If authentication credentials are provided squash matrix will allow
  # considerably more requests for an IP address and allow forbidden conent
  # to be requested.

  class Client
    # Returns params to create existing authenticated client
    # @return [Hash]

    def get_save_params
      {
        player: @player,
        email: @email,
        password: @password,
        suppress_errors: @suppress_errors,
        timeout: @timeout,
        user_agent: @user_agent,
        cookie: get_cookie_string,
        expires: @expires.to_s,
        proxy_addr: @proxy_addr,
        proxy_port: @proxy_port
      }.delete_if { |_k, v| v.nil? }
    end

    # Returns newly created Client
    # @note If suppress_errors == false SquashMatrix::Errors::AuthorizationError will be raised if specified credentials are incorrect and squash matrix authentication returns forbidden
    # @param [Hash] opts the options to create client
    # @return [Client]

    def initialize(player: nil,
                   email: nil,
                   password: nil,
                   suppress_errors: false,
                   timeout: 60,
                   user_agent: nil,
                   cookie: nil,
                   expires: nil,
                   proxy_addr: nil,
                   proxy_port: nil)
      @user_agent = user_agent || UserAgentRandomizer::UserAgent.fetch(type: 'desktop_browser').string
      @squash_matrix_home_uri = URI::HTTP.build(host: SquashMatrix::Constants::SQUASH_MATRIX_URL)
      @suppress_errors = suppress_errors
      @timeout = timeout
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      return unless [player || email, password].none?(&:nil?)
      @cookie_jar = HTTP::CookieJar.new
      @player = player&.to_i
      @email = email
      @password = password
      @expires = !expires.to_s.empty? && Time.parse(expires).utc
      if cookie && @expires > Time.now.utc
        cookie.split('; ').each do |v|
          @cookie_jar.parse(v, @squash_matrix_home_uri)
        end
      else
        setup_authentication
      end
    end

    # Returns club info.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Fixnum] club id found on squash matrix
    # @return [Hash] hash object containing club information

    def get_club_info(id = nil)
      return unless id.to_i.positive?
      uri = URI::HTTP.build(
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::CLUB_PATH.gsub(':id', id.to_s)
      )
      success_proc = lambda do |res|
        SquashMatrix::NokogiriParser.get_club_info(res.body)
      end
      handle_http_request(uri, success_proc)
    end

    # Returns player results.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Fixnum] played id found on squash matrix
    # @return [Array<Hash>] Array of player match results

    def get_player_results(id = nil)
      return unless id.to_i.positive?
      uri = URI::HTTP.build(
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::PLAYER_RESULTS_PATH.gsub(':id', id.to_s),
        query: SquashMatrix::Constants::PLAYER_RSULTS_QUERY
      )
      success_proc = lambda do |res|
        SquashMatrix::NokogiriParser.get_player_results(res.body)
      end
      handle_http_request(uri, success_proc)
    end

    # Returns player info.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Fixnum] played id found on squash matrix
    # @return [Hash] hash object containing player information

    def get_player_info(id = nil)
      return unless id.to_i.positive?
      uri = URI::HTTP.build(
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::PLAYER_HOME_PATH.gsub(':id', id.to_s)
      )
      success_proc = lambda do |res|
        SquashMatrix::NokogiriParser.get_player_info(res.body)
      end
      handle_http_request(uri, success_proc)
    end

    # Returns get_search_results results
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param query [String] get_search_results query
    # @return [Hash] hash object containing get_search_results results

    def get_search_results(query = nil,
                           squash_only: false,
                           racquetball_only: false)
      return if query.to_s.empty?
      uri = URI::HTTP.build(
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::SEARCH_RESULTS_PATH
      )
      query_params = {
        Criteria: query,
        SquashOnly: squash_only,
        RacquetballOnly: racquetball_only
      }
      success_proc = lambda do |res|
        SquashMatrix::NokogiriParser.get_search_results(res.body)
      end
      handle_http_request(uri, success_proc,
                          is_get_request: false,
                          query_params: query_params)
    end

    private

    def check_authentication
      return unless @expires && @cookie_jar && @expires <= (Time.now.utc + @timeout)
      @cookie_jar = HTTP::CookieJar.new
      setup_authentication && sleep(5)
    end

    def handle_http_request(uri, success_proc,
                            is_get_request: true,
                            query_params: nil,
                            headers: nil,
                            is_authentication_request: false)
      Timeout.timeout(@timeout) do
        check_authentication unless is_authentication_request
        if is_get_request
          req = Net::HTTP::Get.new(uri)
          set_headers(req, headers: headers)
        else
          req = Net::HTTP::Post.new(uri)
          set_headers(req)
          form_data = []
          query_params.each do |key, value|
            form_data.push([key.to_s, value.to_s])
          end
          set_headers(req, headers: headers)
          req.set_form(form_data, SquashMatrix::Constants::MULTIPART_FORM_DATA)
        end
        res = Net::HTTP.start(uri.hostname, uri.port, @proxy_addr, @proxy_port&.to_i, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
        case res
        when Net::HTTPSuccess, Net::HTTPFound
          return success_proc&.call(res) || res
        when Net::HTTPConflict
          unless @suppress_errors
            raise SquashMatrix::Errors::ForbiddenError, res.body if SquashMatrix::Constants::FORBIDDEN_ERROR_REGEX.match(res.body)
            raise SquashMatrix::Errors::TooManyRequestsError, res.body if SquashMatrix::Constants::TOO_MANY_REQUESTS_ERROR_REGEX.match(res.body)
          end
        else
          raise SquashMatrix::Errors::UnknownError, res unless @suppress_errors
        end
      end
    rescue Timeout::Error => e
      raise e unless @suppress_errors
    end

    def setup_authentication
      uri = URI::HTTPS.build(
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::LOGIN_PATH
      )
      query_params = {
        UserName: @player&.to_s || @email,
        Password: @password,
        RememberMe: true
      }
      headers = {
        SquashMatrix::Constants::CONTENT_TYPE_HEADER => SquashMatrix::Constants::MULTIPART_FORM_DATA
      }
      # need to retrieve the asp.net session id
      home_page_res = handle_http_request(@squash_matrix_home_uri,
                                          nil,
                                          is_authentication_request: true)
      raise SquashMatrix::Errors::AuthorizationError, SquashMatrix::Constants::ERROR_RETRIEVING_ASPNET_SESSION unless home_page_res
      home_page_res[SquashMatrix::Constants::SET_COOKIE_HEADER].split('; ').each do |v|
        @cookie_jar.parse(v, @squash_matrix_home_uri)
      end
      res = handle_http_request(uri, nil,
                                is_get_request: false,
                                query_params: query_params,
                                headers: headers,
                                is_authentication_request: true)
      raise SquashMatrix::Errors::AuthorizationError, SquashMatrix::Constants::ERROR_RETRIEVING_ASPAUX_TOKEN unless res
      res[SquashMatrix::Constants::SET_COOKIE_HEADER]&.split('; ')&.each do |v|
        parts = SquashMatrix::Constants::EXPIRES_FROM_COOKIE_REGEX.match(v)
        @expires = Time.parse(parts[1]).utc if parts
        @cookie_jar.parse(v, @squash_matrix_home_uri)
      end
      @expires ||= Time.now.utc + 60 * 60 * 24 * 2 # default expires in two days (usually 52 hours)
      @player = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(res[SquashMatrix::Constants::LOCATION_HEADER])[1] if @player.nil? && !res[SquashMatrix::Constants::LOCATION_HEADER].to_s.empty?
      return unless !@suppress_errors && !@cookie_jar&.cookies(@squash_matrix_home_uri)&.find { |c| c.name == SquashMatrix::Constants::ASPXAUTH_COOKIE_NAME && !c.value.to_s.empty? }
      error_string = SquashMatrix::NokogiriParser.get_log_on_error(res.body).join(', ')
      raise SquashMatrix::Errors::AuthorizationError, error_string
    end

    def set_headers(req = nil, headers: nil)
      return unless req
      headers_to_add = {
        SquashMatrix::Constants::USER_AGENT_HEADER => @user_agent,
        SquashMatrix::Constants::HOST_HEADER => SquashMatrix::Constants::SQUASH_MATRIX_URL
      }
      headers_to_add = headers_to_add.merge(headers) if headers
      headers_to_add = headers_to_add.merge(SquashMatrix::Constants::COOKIE_HEADER => get_cookie_string) if @cookie_jar
      headers_to_add.each { |key, val| req[key.to_s] = val }
    end

    def get_cookie_string
      return unless @cookie_jar
      cookies = @cookie_jar.cookies(@squash_matrix_home_uri).select do |c|
        [
          SquashMatrix::Constants::ASP_NET_SESSION_ID_COOKIE_NAME,
          SquashMatrix::Constants::GROUP_ID_COOKIE_NAME,
          SquashMatrix::Constants::ASPXAUTH_COOKIE_NAME
        ].include?(c.name)
      end
      HTTP::Cookie.cookie_value(cookies)
    end
  end
end
