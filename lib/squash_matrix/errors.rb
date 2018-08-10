module SquashMatrix
  module Errors
    class AuthorizationError < StandardError; end
    class ForbiddenError < StandardError; end
    class UnknownError < StandardError; end
  end
end
