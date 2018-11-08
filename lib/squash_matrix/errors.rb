# frozen_string_literal: true

module SquashMatrix
  module Errors
    class TooManyRequestsError < StandardError; end
    class AuthorizationError < StandardError; end
    class ForbiddenError < StandardError; end
    class UnknownError < StandardError; end
    class EntityNotFoundError < StandardError; end
  end
end
