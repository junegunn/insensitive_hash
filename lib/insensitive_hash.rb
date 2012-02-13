require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  # @return [InsensitiveHash]
  def insensitive options = { :underscore => false }
    InsensitiveHash[ self ].tap do |ih|
      ih.underscore = options[:underscore] if options.has_key?(:underscore)
    end
  end
end

