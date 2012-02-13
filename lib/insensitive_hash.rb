require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  # @yield [key] Specifies how to encode a String key
  # @yieldparam [String] key
  # @yieldreturn [String]
  # @return [InsensitiveHash]
  def insensitive &encoder
    InsensitiveHash[ self ].tap { |h|
      h.encoder = encoder if encoder
    }
  end
end

