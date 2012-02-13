class InsensitiveHash < Hash
  class KeyClashError < Exception
  end

  def initialize default = nil, &block
    if block_given?
      super &block
    else
      super
    end

    @key_map    = {}
    @underscore = false
  end

  # Sets whether to replace spaces in String keys to underscores
  # @param [Boolean] us
  # @return [Boolean]
  def underscore= us
    raise ArgumentError.new("Not true or false") unless [true, false].include?(us)

    # Check key clash
    detect_clash self, us

    @underscore = us
    @key_map    = {}
    self.keys.each do |k|
      self[k] = self.delete(k)
    end

    us
  end

  # @return [Boolean] Whether to replace spaces in String keys to underscores
  def underscore?
    @underscore
  end
  
  # Returns a normal, sensitive Hash
  # @return [Hash]
  def to_hash
    {}.merge self
  end
  alias sensitive to_hash

  def self.[] *init
    h = Hash[*init]
    InsensitiveHash.new.tap do |ih|
      h.each do |key, value|
        ih[key] = value
      end
    end
  end

  %w[[] assoc has_key? include? key? member?].each do |symb|
    class_eval <<-EVAL
      def #{symb} key
        super lookup_key(key)
      end
    EVAL
  end

  def []= key, value
    delete key
    ekey = encode key, @underscore
    @key_map[ekey] = key
    super key, wrap(value, underscore?)
  end
  alias store []=

  def merge! other_hash
    detect_clash other_hash, underscore?
    other_hash.each do |key, value|
      self[key] = value
    end
    self
  end
  alias update! merge!

  def merge other_hash
    InsensitiveHash[self].tap do |ih|
      ih.underscore = self.underscore?
      ih.merge! other_hash
    end
  end
  alias update merge

  def delete key, &block
    super lookup_key(key, true), &block
  end

  def clear
    @key_map.clear
    super
  end

  def replace other
    detect_clash other, underscore?

    clear
    other.each do |k, v|
      self[k] = v
    end
  end

  def shift
    super.tap do |ret|
      @key_map.delete_if { |k, v| v == ret.first }
    end
  end

  def values_at *keys
    keys.map { |k| self[k] }
  end

  def fetch *args, &block
    args[0] = lookup_key(args[0]) if args.first
    super *args, &block
  end

private
  def wrap value, us
    case value
    when InsensitiveHash
      value.tap { |ih| ih.underscore = us || ih.underscore? }
    when Hash
      InsensitiveHash[value].tap { |ih| ih.underscore = us }
    when Array
      value.map { |v| wrap v, us }
    else
      value
    end
  end

  def lookup_key key, delete = false
    ekey = encode key, @underscore
    if @key_map.has_key?(ekey)
      delete ? @key_map.delete(ekey) : @key_map[ekey]
    else
      key
    end
  end

  def encode key, us
    case key
    when String, Symbol
      key = key.to_s.downcase
      if us
        key.gsub(' ', '_')
      else
        key
      end
    else
      key
    end
  end

  def detect_clash hash, us
    hash.keys.map { |k| encode k, us }.tap { |ekeys|
      raise KeyClashError.new("Key clash detected") if ekeys != ekeys.uniq
    }
  end
end

