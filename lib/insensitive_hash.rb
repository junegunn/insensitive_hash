require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  # @return [InsensitiveHash]
  def insensitive options = {}
    InsensitiveHash.new.tap do |ih|
      ih.replace self
      ih.underscore = options[:underscore] if options.has_key?(:underscore)
      ih.safe       = options[:safe]       if options.has_key?(:safe)
    end
  end
end

