# frozen_string_literal: true

module SquashMatrix
  module Constants
    SQUASH_MATRIX_URL = 'www.squashmatrix.com'
    LOGIN_PATH = '/Account/LogOn'
    PLAYER_RESULTS_PATH = '/Home/PlayerResults/:id'
    PLAYER_HOME_PATH = '/Home/Player/:id'
    CLUB_PATH = '/Home/Club/:id'
    SEARCH_RESULTS_PATH = '/Home/Search'
    PLAYER_RSULTS_QUERY = 'max=0&X-Requested-With=XMLHttpRequest'
    SET_COOKIE_HEADER = 'set-cookie'
    COOKIE_HEADER = 'cookie'
    LOCATION_HEADER = 'location'
    X_WWW__FROM_URL_ENCODED = 'application/x-www-form-urlencoded'
    MULTIPART_FORM_DATA = 'multipart/form-data'
    CONTENT_TYPE_HEADER = 'content-type'
    REFERER = 'Home/Player/:id'
    ASPXAUTH_COOKIE_NAME = '.ASPXAUTH'
    ASP_NET_SESSION_ID_COOKIE_NAME = 'ASP.NET_SessionId'
    GROUP_ID_COOKIE_NAME = 'GroupId'
    HOST_HEADER = 'host'
    USER_AGENT_HEADER = 'user-agent'
    EXPIRES_COOKIE_NAME = 'expires'

    PLAYER_FROM_PATH_REGEX = /\/Home\/Player\/(.*)/
    TEAM_FROM_PATH_REGEX = /\/Home\/Team\/(.*)/
    CLUB_FROM_PATH_REGEX = /\/Home\/Club\/(.*)/
    MATCH_FROM_PATH_REGEX = /\/Home\/Match\/(.*)/
    CLUB_FROM_TITLE_REGEX = /Club - (.*)/
    EXPIRES_FROM_COOKIE_REGEX = /expires=(.*)/

    ERROR_RETRIEVING_ASPNET_SESSION = 'Error retrieving ASP.NET_SessionId'
    ERROR_RETRIEVING_ASPAUX_TOKEN = 'Error retrieving .ASPXAUTH_TOKEN'

    TOO_MANY_REQUESTS_ERROR_REGEX = /Request made too soon. This is to prevent abuse to the site. We apologise for the inconvenience/
    FORBIDDEN_ERROR_REGEX = /Forbidden/
  end
end
