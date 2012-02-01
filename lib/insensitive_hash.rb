require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  def insensitive
    InsensitiveHash[ self ]
  end
end

