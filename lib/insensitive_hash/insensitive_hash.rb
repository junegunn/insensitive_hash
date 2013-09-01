# Insensitive Hash.
# @author Junegunn Choi <junegunn.c@gmail.com>
# @!attribute [r] encoder
#   @return [#call] Key encoder. Determines the level of insensitivity.
class InsensitiveHash < Hash
  attr_reader :encoder

  # Thrown when safe mode is on and another Hash with conflicting keys cannot be merged safely
  class KeyClashError < Exception
  end

  DEFAULT_ENCODER = proc { |key|
    case key
    when String, Symbol
      key.to_s.downcase.gsub(' ', '_')
    else
      key
    end
  }

  def initialize default = nil, &block
    if block_given?
      raise ArgumentError.new('wrong number of arguments') unless default.nil?
      super(&block)
    else
      super
    end

    @key_map = {}
    @safe    = false
    @encoder = DEFAULT_ENCODER
  end

  # Sets whether to detect key clashes
  # @param [Boolean]
  # @return [Boolean]
  def safe= s
    raise ArgumentError.new("Neither true nor false") unless [true, false].include?(s)
    @safe = s
  end

  # @return [Boolean] Key-clash detection enabled?
  def safe?
    @safe
  end

  # @param [#call] prc Key encoder. Determines the level of insensitivity.
  # @return [#call]
  def encoder= prc
    raise ArgumentError, "Encoder must respond to :call" unless prc.respond_to?(:call)

    kvs = to_a
    clear
    @encoder = prc
    kvs.each do |pair|
      store(*pair)
    end

    prc
  end

  # Returns a normal, sensitive Hash
  # @return [Hash]
  def to_hash
    {}.merge self
  end
  alias sensitive to_hash

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def self.[] *init
    h = Hash[*init]
    self.new.tap do |ih|
      ih.merge_recursive! h
    end
  end

  %w[[] assoc has_key? include? key? member?].each do |symb|
    class_eval <<-EVAL
      def #{symb} key
        super lookup_key(key)
      end
    EVAL
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def []= key, value
    delete key
    ekey = encode key
    @key_map[ekey] = key
    super key, value
  end
  alias store []=

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def merge! other_hash
    detect_clash other_hash
    other_hash.each do |key, value|
      store key, value
    end
    self
  end
  alias update! merge!

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def merge other_hash
    self.class.new.tap do |ih|
      ih.replace self
      ih.merge! other_hash
    end
  end
  alias update merge

  # Merge another hash recursively.
  # @param [Hash|InsensitiveHash] other_hash
  # @return [self]
  def merge_recursive! other_hash
    detect_clash other_hash
    other_hash.each do |key, value|
      deep_set key, value
    end
    self
  end
  alias update_recursive! merge_recursive!

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def delete key, &block
    super lookup_key(key, true), &block
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def clear
    @key_map.clear
    super
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def replace other
    super other

    self.safe = other.respond_to?(:safe?) ? other.safe? : safe?
    self.encoder = other.respond_to?(:encoder) ? other.encoder : DEFAULT_ENCODER

    @key_map.clear
    self.each do |k, v|
      ekey = encode k
      @key_map[ekey] = k
    end
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def shift
    super.tap do |ret|
      @key_map.delete_if { |k, v| v == ret.first }
    end
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def values_at *keys
    keys.map { |k| self[k] }
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def fetch *args, &block
    args[0] = lookup_key(args[0]) if args.first
    super(*args, &block)
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def dup
    super.tap { |copy|
      copy.instance_variable_set :@key_map, @key_map.dup
    }
  end

  # @see http://www.ruby-doc.org/core-1.9.3/Hash.html Hash
  def clone
    super.tap { |copy|
      copy.instance_variable_set :@key_map, @key_map.dup
    }
  end

private
  def deep_set key, value
    wv = wrap value
    self[key] = wv
  end

  def wrap value
    case value
    when InsensitiveHash
      value.tap { |ih|
        ih.safe = safe?
        ih.encoder = encoder
      }
    when Hash
      self.class.new.tap { |ih|
        ih.safe = safe?
        ih.encoder = encoder
        ih.merge_recursive!(value)
      }
    when Array
      value.map { |v| wrap v }
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
    @encoder.call key
  end

  def detect_clash hash
    hash.keys.map { |k| encode k }.tap { |ekeys|
      raise KeyClashError.new("Key clash detected") if ekeys != ekeys.uniq
    } if @safe
  end
end

