class InsensitiveHash < Hash
  attr_reader :key_map

  def initialize default = nil, &block
    if block_given?
      super &block
    else
      super
    end

    @key_map = {}
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
    ekey = encode key
    if @key_map.has_key? ekey
      delete @key_map[ekey]
    end

    @key_map[encode key] = key
    super(lookup_key(key), InsensitiveHash.wrap(value))
  end
  alias store []=

  def merge! other_hash
    other_hash.each do |key, value|
      self[key] = value
    end
    self
  end
  alias update! merge!

  def merge other_hash
    InsensitiveHash[self].tap do |ih|
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

private
  def self.wrap value
    case value
    when Hash
      value.class == InsensitiveHash ? value : InsensitiveHash[value]
    when Array
      value.map { |v| InsensitiveHash.wrap v }
    else
      value
    end
  end

  def lookup_key key, delete = false
    ekey = encode key
    if @key_map.has_key?(ekey)
      delete ? @key_map.delete(ekey) : @key_map[ekey]
    else
      key
    end
  end

  def encode key
    case key
    when String
      key.downcase
    when Symbol
      key.to_s.downcase
    else
      key
    end
  end
end

