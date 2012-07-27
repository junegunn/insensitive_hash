require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  # @return [InsensitiveHash]
  def insensitive options = {}
    InsensitiveHash[self].tap do |ih|
      ih.safe         = options[:safe] if options.has_key?(:safe)
      ih.default      = self.default
      ih.default_proc = self.default_proc if self.default_proc
    end
  end
end

