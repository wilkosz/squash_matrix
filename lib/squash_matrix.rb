require 'squash_matrix/version'
require_relative 'squash_matrix/client'

# Public: Generates clients for information retrieval from squashmatrix.com
#
# Examples
#
#   SquashMatrix::Client.new({player: 5247, password: 'foo'})
#   # => SquashMatrix::Client


# ==== Examples
#
#   SquashMatrix::Client.new
#   SquashMatrix::Client.new({player: 5247, password: 'foo'})
#   SquashMatrix::Client.new({player: 5247, password: 'foo', suppress_errors: true})
#   SquashMatrix::Client.new({player: 5247, password: 'foo', timeout: 180}) 
module SquashMatrix

end
