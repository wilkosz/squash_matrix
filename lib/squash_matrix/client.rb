require 'net/http'
require 'date'
require 'timeout'
require 'http-cookie'
require_relative 'constants'
require_relative 'nokogiri-parser'
require_relative 'errors'

module SquashMatrix

  # Client for retrieving player and club information from squashmatrix.com.
  # If authentication credentials are provided squash matrix will allow
  # considerably more requests for an IP address and allow forbidden conent
  # to be requested.

  class Client

    # Returns newly created Client
    # @note If suppress_errors == false SquashMatrix::Errors::AuthorizationError will be raised if specified credentials are incorrect and squash matrix authentication returns forbidden
    # @param [Hash] opts the options to create client
    # @return [Client]

    def initialize(player: nil, email: nil, password: nil, suppress_errors: false, timeout: 60)
      @squash_matrix_home_uri = URI::HTTP.build({ host: SquashMatrix::Constants::SQUASH_MATRIX_URL, path: '/'})
      @suppress_errors = suppress_errors
      @timeout = timeout
      if ![player || email, password].any?(&:nil?)
        @cookie_jar = HTTP::CookieJar.new()
        @player = player
        @email = email
        @password = password
        authenticate
      end
    end

    # Returns club info.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Fixnum] club id found on squash matrix
    # @return [Hash] hash object containing club information

    def club_info(id=nil)
      return if id.nil?
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::CLUB_PATH.gsub(':id', id.to_s)
        })
      success_proc = lambda {|res| SquashMatrix::NokogiriParser.club_info(res.body)}
      handle_http_request(uri, success_proc)
    end

    # Returns player info.
    # @note If suppress_errors == false SquashMatrix Errors will be raised upon HttpNotFound, HttpConflict, Timeout::Error, etc...
    # @param id [Fixnum] played id found on squash matrix
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
        SquashOnly: squash_only,
        RacquetballOnly: racquetball_only}
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
            res = Net::HTTP.start(uri.hostname, uri.port, {use_ssl: uri.scheme == 'https'}) {|http| http.request(req)}
          else
            res = Net::HTTP.post_form(uri, query_params)
          end
          # binding.pry if /Request made too soon. This is to prevent abuse to the site. We apologise for the inconvenience/.match(res.body)
          # binding.pry if /Forbidden/.match(res.body)
          case res
          when Net::HTTPSuccess, Net::HTTPFound
            return success_proc && success_proc.call(res) || res
          when Net::HTTPConflict
            # res.body == "Forbidden"
            # find error? Request made too soon. This is to prevent abuse to the site. We apologise for the inconvenience.
            raise SquashMatrix::Errors::ForbiddenError.new(res.body) unless @suppress_errors
          else
            raise SquashMatrix::Errors::UnknownError.new(res) unless @suppress_errors
          end
        end
      rescue Timeout::Error => e
        raise e unless @suppress_errors
      end
    end

    def authenticate
      uri = URI::HTTP.build({
        host: SquashMatrix::Constants::SQUASH_MATRIX_URL,
        path: SquashMatrix::Constants::LOGIN_PATH})
      headers = {
        SquashMatrix::Constants::CONTENT_TYPE_HEADER.to_sym => SquashMatrix::Constants::X_WWW__FROM_URL_ENCODED
      }
      query_params = {
        UserName: @player&.to_s || @email,
        Password: @password,
        RememberMe: false
      }
      home_page_res = handle_http_request(@squash_matrix_home_uri, nil)
      raise SquashMatrix::Errors::AuthorizationError.new("Error retrieving ASP.NET_SESSION info") unless home_page_res
      home_page_res['set-cookie'].split('; ').each do |v|
        @cookie_jar.parse(v, @squash_matrix_home_uri)
      end
      res = handle_http_request(uri, nil,
        {
          is_get_request: false,
          query_params: query_params,
          headers: headers
        })
      raise SquashMatrix::Errors::AuthorizationError.new("Error retrieving .ASPXAUTH_TOKEN") unless res
      res['set-cookie'].split('; ').each do |v|
        @cookie_jar.parse(v, @squash_matrix_home_uri)
      end
      @player = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(res[SquashMatrix::Constants::LOCATION_HEADER])[1] if @player.nil? && res[SquashMatrix::Constants::LOCATION_HEADER]
      unless !@suppress_errors && @cookie_jar.cookies(@squash_matrix_home_uri).find {|c| c.name == SquashMatrix::Constants::ASPXAUTH_COOKIE_NAME && !c.value.empty?}
        error_string = SquashMatrix::NokogiriParser.log_on_error(res.body).join(', ')
        raise SquashMatrix::Errors::AuthorizationError.new(error_string)
      end
    end

    def set_headers(req=nil, headers: nil)
      return unless req
      headers_to_add = {}
      headers_to_add.merge(headers) if headers
      if @cookie_jar
        cookies = @cookie_jar.cookies(@squash_matrix_home_uri).select do |c|
          [
            SquashMatrix::Constants::ASPXAUTH_COOKIE_NAME,
            SquashMatrix::Constants::ASP_NET_SESSION_ID_COOKIE_NAME,
            SquashMatrix::Constants::GROUP_ID_COOKIE_NAME
          ].include?(c.name)
        end
        headers_to_add.merge({'cookie': HTTP::Cookie.cookie_value(cookies)})
      end
      headers_to_add.each {|key, val| req[key] = val}
    end
  end
end
