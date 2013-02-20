require 'insensitive_hash/version'
require 'insensitive_hash/insensitive_hash'

class Hash
  # @param [Hash] options Options
  # @option options [Boolean] :safe Whether to detect key clash on merge
  # @option options [Proc] :encoder Key encoding Proc
  # @return [InsensitiveHash]
  def insensitive options = {}
    InsensitiveHash[self].tap do |ih|
      ih.safe         = options[:safe] if options.has_key?(:safe)
      ih.encoder      = options[:encoder] if options.has_key?(:encoder)
      ih.default      = self.default
      ih.default_proc = self.default_proc if self.default_proc
    end
  end
end

