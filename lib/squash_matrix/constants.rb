
module SquashMatrix
  module Constants
    SQUASH_MATRIX_URL = "www.squashmatrix.com"
    LOGIN_PATH = "/Account/LogOn"
    PLAYER_PATH = "/Home/PlayerResults/:id"
    CLUB_PATH = "/Home/Club/:id"
    SEARCH_PATH = "/Home/Search"
    PLAYER_RSULTS_QUERY = "max=0&X-Requested-With=XMLHttpRequest"
    SET_COOKIE_HEADER = 'set-cookie'
    LOCATION_HEADER = 'location'
    X_WWW__FROM_URL_ENCODED = 'application/x-www-form-urlencoded'
    MULTIPART_FORM_DATA = 'multipart/form-data'
    CONTENT_TYPE_HEADER = 'Content-Type'
    REFERER = "Home/Player/:id"
    ASPXAUTH_COOKIE_NAME = ".ASPXAUTH"
    ASP_NET_SESSION_ID_COOKIE_NAME = "ASP.NET_SessionId"
    GROUP_ID_COOKIE_NAME = "GroupId"

    PLAYER_FROM_PATH_REGEX = /\/Home\/Player\/(.*)/
    TEAM_FROM_PATH_REGEX = /\/Home\/Team\/(.*)/
    CLUB_FROM_PATH_REGEX = /\/Home\/Club\/(.*)/
    MATCH_FROM_PATH_REGEX = /\/Home\/Match\/(.*)/
    CLUB_FROM_TITLE_REGEX = /Club - (.*)/
  end
end
