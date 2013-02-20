require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)
require 'test/unit'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'insensitive_hash'

class TestInsensitiveHash < Test::Unit::TestCase
  def eight?
    RUBY_VERSION =~ /^1\.8\./
  end

  def assert_keys set1, set2
    if eight?
      assert_equal set1.sort { |a, b| a.to_s <=> b.to_s },
        set2.sort { |a, b| a.to_s <=> b.to_s }
    else
      assert_equal set1, set2
    end
  end

  def test_has_key_set
    ih = InsensitiveHash.new
    ih['a'] = 1
    ih.store 'A', 2

    ['a', 'A', :a, :A].each do |a|
      assert       ih.has_key?(a)
      assert       ih.key?(a)
      assert       ih.include?(a)
      assert       ih.member?(a)
      assert_equal 2, ih[a]
    end

    assert_keys  ['A'], ih.keys
    assert_equal [2], ih.values

    ih[:A] = 4
    assert_keys  [:A], ih.keys
    assert_equal [4], ih.values

    ih[:b] = { :c => 5 }
    assert          ih.keys.include?(:A)
    assert          ih.keys.include?(:b)
    assert_equal 2, ih.keys.length
    assert_equal({ :c => 5 }, ih['B'])
    assert_equal 5, ih['B'][:c]
    assert_equal nil, ih['B']['C']

    ih['c'] = [ { 'x' => 1 }, { :y => 2 } ]
    assert       ih.keys.include?('c')
    assert_equal 3, ih.keys.length

    assert_equal nil, ih[:c].first[:x]
    assert_equal nil, ih[:c].last['Y']

    ih = ih.insensitive
    assert_equal 1, ih[:c].first[:x]
    assert_equal 2, ih[:c].last['Y']

    # Deeeeeper nesting
    ih['c'] = [ [ [ { 'x' => 1 }, { :y => 2 } ] ] ]
    assert_equal nil, ih[:c].first.first.last[:Y]
    ih = ih.insensitive
    assert_equal 2, ih[:c].first.first.last[:Y]

    ih['c'] = { 'a' => { 'a' => { 'a' => 100 } } }.insensitive
    assert_equal 100, ih[:C][:a][:A]['A']

    ih[5] = 50
    assert_equal 50, ih[5]
  end

  def test_from_hash
    hash = {
      'a' => 1,
      'B' => 2,
      :c  => { :D => [ { 'e' => 3 } ] }
    }

    pend("TODO") do
      assert_raise(NoMethodError) {
        hash.insensitive
      }
    end

    [hash.insensitive, InsensitiveHash[hash]].each do |ih|
      assert       ih.is_a?(Hash)
      assert_equal InsensitiveHash, ih.class
      ['c', 'C', :c, :C].each do |c|
        assert_equal InsensitiveHash, ih[c].class

        ['d', 'D', :d, :D].each do |d|
          assert_equal InsensitiveHash, ih[c][d].first.class
        end
      end
    end

    # Changelog 0.3.0
    ih = {}.insensitive
    ih[:a] = { :b => :c }
    assert_nil ih[:a]['B']
    ih2 = ih.insensitive
    assert_equal :c, ih2[:a]['B']

    # InsensitiveHash#insensitive
    ihash1 = hash.insensitive
    ihash1.default = :default
    ihash2 = ihash1.insensitive.insensitive.insensitive

    assert_equal InsensitiveHash, ihash2.class
    assert_equal :default, ihash2.default

    # Preserving default
    [:default, nil].each do |d|
      hash.default = d
      assert_equal d, hash.insensitive.insensitive.insensitive[:anything]
    end

    # Preserving default_proc
    unless eight?
      hash2 = {}
      hash2.replace hash
      hash2.default_proc = proc { |h, k| h[k] = :default }

      ihash2 = hash2.insensitive.insensitive.insensitive
      assert !ihash2.has_key?(:anything)
      assert_equal :default, ihash2[:anything]
      assert ihash2.has_key?(:anything)
    end

    # FIXME: test insensitive call with encoder
    h = InsensitiveHash[{'Key with spaces' => 1}]
    h2 = h.insensitive

    assert_equal 1, h['key with spaces']
    assert_equal 1, h[:key_with_spaces]
    assert_equal 1, h2[:KEY_WITH_SPACES]
    assert_equal 1, h2[:Key_with_spaces]

    assert_equal ['Key with spaces'], h.keys
    assert_equal ['Key with spaces'], h2.keys

    h = { 'A key with spaces' => true }
    ih = h.insensitive
    assert ih[:a_key_with_spaces]

    # FIXME: from README
    ih = InsensitiveHash[ h ]
    assert ih[:a_key_with_spaces]

    # :safe
    ih = {}.insensitive
    assert_raise(ArgumentError) {
      ihs = {'a' => 1}.insensitive(:safe => 1)
    }
    ihs = {'a' => 1}.insensitive(:safe => true)
    assert !ih.safe?
    assert ihs.safe?

    assert_raise(InsensitiveHash::KeyClashError) {
      ihs.merge(:a => 2, 'A' => 3)
    }
  end

  def test_delete
    ih = InsensitiveHash[:a => 1]
    assert_equal [:a], ih.keys
    assert_equal [1], ih.values

    assert_equal nil, ih.delete('B')
    assert_equal 1, ih.delete('A')
    assert_equal :notfound, ih.delete('A') { |a| :notfound }
    assert_equal [], ih.keys
  end

  def test_merge
    [:merge, :update].each do |method|
      ih = InsensitiveHash[:a => 1, 'hello world' => 2]
      ih2 = ih.send(method, :b => 2)

      assert_keys [:a, 'hello world'], ih.keys
      assert_keys [:a, 'hello world', :b], ih2.keys
      assert ih2.has_key?('B'), 'correctly merged another hash'

      assert_equal 2, ih[:hello_world]
      assert_equal 2, ih.send(method, :b => 2)[:hello_world]

      ih.default = 10
      assert_equal 10, ih.send(method, :b => 2)[:anything]

      ih.default = nil
      assert_nil ih.send(method, :b => 2)[:anything]

      unless eight?
        ih.default_proc = proc { |h, k| h[k] = :default }
        mh = ih.send(method, :b => 2)
        assert       !mh.has_key?(:anything)
        assert_equal :default, mh[:anything]
        assert        mh.has_key?(:anything)
      end

      ih2.delete 'b'
      assert ih2.has_key?('B') == false
    end
  end

  def test_merge!
    [:merge!, :update!].each do |method|
      ih = InsensitiveHash[:a => 1]
      ih2 = ih.send(method, :b => 2)

      assert_keys [:a, :b], ih.keys
      assert_keys [:a, :b], ih2.keys
      assert ih2.has_key?('B'), 'correctly merged another hash'

      ih2.delete 'b'
      assert ih2.has_key?('B') == false
    end
  end

  def test_merge_clash_overwritten
    ih = InsensitiveHash.new

    ih = ih.merge(:a => 1, :A =>2)
    # No guarantee in order in 1.8
    unless eight?
      assert_equal 2, ih.values.first
      assert_equal 2, ih['A']
    end
    assert_equal 1, ih.length

    ih = InsensitiveHash.new
    ih.merge!(:hello_world => 1, 'hello world' =>2)
    unless eight?
      assert_equal 2, ih.values.first
      assert_equal 2, ih[:Hello_World]
    end
    assert_equal 1, ih.length
  end

  def test_merge_clash
    ih = InsensitiveHash.new
    ih2 = InsensitiveHash.new

    sih = InsensitiveHash.new
    sih.safe = true

    [:merge, :merge!, :update, :update!].each do |method|
      # No problem
      [ih, ih2].each do |h|
        h.send(method, { :a => 1, :A => 1, 'A' => 1})
        h.send(method, { 'a' => 1, 'A' => 1 })
      end

      assert_raise(InsensitiveHash::KeyClashError) {
        sih.send(method, { :a => 1, :A => 1, 'A' => 1})
      }
      assert_raise(InsensitiveHash::KeyClashError) {
        sih.send(method, { 'a' => 1, 'A' => 1 })
      }

      assert_raise(InsensitiveHash::KeyClashError) {
        sih.send(method, { :hello_world => 1, 'hello world' => 2})
      }
      ih2.send(method, { :hello_world => 1, 'hello world' => 2})
    end

    ih.merge({ :a => 1, :A => 1, 'A' => 1})
    assert_raise(InsensitiveHash::KeyClashError) {
      sih.merge({ :a => 1, :A => 1, 'A' => 1})
    }
  end

  def test_assoc
    pend "1.8" if eight?

    h = InsensitiveHash[{
      "colors"  => ["red", "blue", "green"],
      :Letters => ["a", "b", "c" ]
    }]
    assert_equal [:Letters, ["a", "b", "c"]], h.assoc("letters")
    assert_equal ["colors", ["red", "blue", "green"]], h.assoc(:COLORS)
  end

  def test_clear_empty?
    h = InsensitiveHash[:a, 1]
    h.clear
    assert_equal [], h.keys
    assert h.empty?
  end

  def test_to_hash
    h = InsensitiveHash[:a, 1, :b, {:c => 2}]
    assert_equal 1, h[:A]
    assert_equal 2, h['B']['C']

    h = h.to_hash
    assert_equal Hash, h.class
    assert_equal nil, h[:A]
    assert_equal 1, h[:a]
    assert_equal 2, h[:b][:c]
    pend("TBD: Recursive conversion") do
      assert_equal nil, h[:b]['C']
    end
  end

  def test_compare_by_identity
    pend 'Not Implemented'

    key = 'a'
    key2 = 'a'.clone
    h = InsensitiveHash.new
    h[key] = 1
    h[:b] = 2

    assert !h.compare_by_identity?

    assert_equal 1, h['A']
    assert_equal 2, h[:b]
    h.compare_by_identity

    assert h.compare_by_identity?

    assert_equal nil, h[key2]
    assert_equal nil, h[key]
    assert_equal 2,   h[:B]

    h[key] = 3
    assert_not_equal 'a'.object_id, key.object_id
    assert_equal nil, h[key2]
    assert_equal 3,   h[key]
  end

  def test_initializer
    # Hash
    h = InsensitiveHash[ { :a => 1 } ]
    assert_equal 1, h['A']
    assert_equal [:a], h.keys
    assert_equal [1], h.values

    # Pairs
    h = InsensitiveHash[ 'a', 2, 3, 4 ]
    assert_equal 2, h[:a]

    # Wrong number of arguments
    assert_raise(ArgumentError) { h = InsensitiveHash[ 'a', 2, 3 ] }
  end

  def test_default
    h = InsensitiveHash.new
    assert_nil h.default

    h = InsensitiveHash.new 'a'
    assert_equal 'a', h.default
    assert_equal 'a', h[:not_there]

    h = InsensitiveHash.new { |h, k| h[k] = k == :right ? :ok : nil }
    assert_equal nil, h.default
    assert_equal nil, h.default(:wrong)
    assert_equal :ok, h.default(:right)
  end

  def test_default_proc_patch
    h = InsensitiveHash.new { |h, k| k }
    assert_equal 1, h[1]
    assert_equal 2, h[2]

    h = InsensitiveHash.new { |h, k| h[k] = [] }
    h[:abc] << 1
    h[:abc] << 2
    h[:abc] << 3
    assert_equal [1, 2, 3], h[:abc]

    h = InsensitiveHash.new { |h, k| h[k] = {} }
    h[:abc][:def] = 1
    h[:abc][:ghi] = { :xyz => true }
    assert_equal 1, h[:abc][:def]
    assert_equal true, h[:abc][:ghi][:xyz]
    assert_equal nil, h[:abc][:ghi][:XYZ] # This shouldn't work anymore from 0.3.0

    h = InsensitiveHash.new
    h[:abc] = arr = [1, 2, 3]
    arr << 4
    assert_equal [1, 2, 3, 4], h[:ABC]
  end

  def test_delete_if
    # FIXME: Test passes, but key_map not updated
    h = InsensitiveHash[ :a => 100, :tmp_a => 200, :c => 300 ]
    h.delete_if.each { |k, v| k == :tmp_a }
    assert_keys [:a, :c], h.keys
  end

  def test_has_key_after_delete
    set = [:a, :A, 'a', 'A', :b, :B, 'b', 'B']
    h = InsensitiveHash[ :a => 1, :b => 2 ]
    
    set.each { |s| assert h.has_key?(s) }
    h.delete_if { |k, v| true }
    set.each { |s| assert !h.has_key?(s) }
  end

  def test_nil
    h = InsensitiveHash.new(1)
    h[nil] = 2
    assert h.has_key?(nil)
    assert !h.has_key?(:not_there)
    assert_equal 1, h[:not_there]
    assert_equal 2, h[nil]

    h = InsensitiveHash[ nil => 1 ]
    assert_equal :notfound, h.delete('a') { :notfound }
    assert_equal 1, h.delete(nil) { :notfound }
  end

  def test_each
    h = InsensitiveHash[{ :a => 1, :b => 2, :c => 3}]
    assert_equal 3, h.each.count
  end

  def test_has_value
    h = InsensitiveHash[{ :a => 1, :b => 2, :c => 3}]
    assert h.value?(3)
  end

  def test_replace
    h = InsensitiveHash[:a, 1]
    assert h.has_key?('A')

    h.replace({ :b => 2 })

    assert !h.has_key?('A')
    assert h.has_key?('B')

    # Default value
    h.replace(Hash.new(5))
    assert_equal 5, h[:anything]
    assert_equal [], h.keys

    # Default proc
    h.replace(Hash.new { |h, k| h[k] = :default })
    assert_equal :default, h[:anything]
    assert_equal [:anything], h.keys
  end

  def test_rassoc
    pend "1.8" if eight?

    a = InsensitiveHash[{1=> "one", 2 => "two", 3 => "three", "ii" => "two"}]
    assert_equal [2, "two"], a.rassoc("two")
    assert_nil a.rassoc("four")
  end

  def test_shift
    h = InsensitiveHash[{:a => 1, :b => 2}]
    assert_equal [:a, 1], h.shift
    assert !h.has_key?('A')
    assert h.has_key?('B')
  end

  def test_values_at
    h = InsensitiveHash[{:a => 1, :b => 2}]
    assert_equal [2, 1], h.values_at('B', :A)
  end

  def test_fetch
    h = InsensitiveHash[{:a => 1, :b => 2}]
    ['a', 'A', :A].each do |k|
      assert_equal 1, h.fetch(k)
      assert_equal 1, h.fetch(k) { nil }
    end
    assert_equal 3, h.fetch(:c, 3)
    assert_equal 3, h.fetch(:c) { 3 }
    assert_raise(eight? ? IndexError : KeyError) { h.fetch('D') }
  end

  def test_underscore_inheritance
    h = 
      {
        'Key with spaces' => {
          'Another key with spaces' => 1
        },
        'Key 2 with spaces' =>
          InsensitiveHash['Yet another key with spaces' => 2],
        'Key 3 with spaces' =>
          InsensitiveHash['Yet another key with spaces' => 3]
      }.insensitive

    assert_equal 1,     h['key with spaces']['another key with spaces']

    assert_equal 2, h['key 2 with spaces']['yet another key with spaces']
    assert_equal 2, h['key 2 with spaces'][:yet_another_key_with_spaces]

    assert_equal 3, h['key 3 with spaces']['yet another key with spaces']

    assert_equal 1,    h[:key_with_spaces][:another_key_with_spaces]
    assert_equal 2,    h[:key_2_with_spaces][:yet_another_key_with_spaces]
    assert_equal 3,    h[:key_3_with_spaces][:yet_another_key_with_spaces]
  end

  def test_constructor_default
    h = InsensitiveHash.new :default
    assert_equal :default, h[:xxx]

    h = InsensitiveHash.new { :default_from_block }
    assert_equal :default_from_block, h[:xxx]

    # But not both!
    assert_raise(ArgumentError) {
      InsensitiveHash.new(:default) { :default_from_block }
    }
  end

  def test_dup_clone
    a = InsensitiveHash.new
    a[:key] = :value

    b = a.dup
    b.delete 'key'
    assert_nil b[:key]

    assert_equal :value, a[:key]

    c = a.clone
    c.delete 'KEY'
    assert_nil c[:key]

    assert_equal :value, a[:key]
  end

  def test_encoder
    # With custom encoder
    a = {}.insensitive(:encoder => prc = proc { |key| key.to_s.downcase })
    a['1'] = 'one'
    assert_equal 'one', a[1]
    assert_equal prc, a.encoder

    a['hello world'] = true
    assert_equal true, a['HELLO WORLD']
    assert_equal nil,  a[:HELLO_WORLD]

    # Update encoder
    a.encoder = proc { |key| key.to_s.gsub(' ', '_').downcase }
    assert_equal true, a[:HELLO_WORLD]

    # Update again
    a.encoder = proc { |key| key.to_s }
    assert_equal true, a[:"hello world"]
    assert_equal nil, a['HELLO WORLD']
    assert_equal nil, a[:hello_world]
    assert_equal nil, a[:HELLO_WORLD]
  end

  def test_encoder_invalid_type
    assert_raise(ArgumentError) {
      {}.insensitive(:encoder => 1)
    }
    assert_raise(ArgumentError) {
      h = InsensitiveHash.new
      h.encoder = 1
    }
  end

  def test_encoder_replace
    a = {}.insensitive(:encoder => proc { |key| key })
    b = {}.insensitive(:encoder => proc { |key| key.to_s })
    a[:key] = b[:key] = 1
    assert_equal 1, a[:key]
    assert_equal 1, b[:key]
    assert_nil a['key']
    assert_equal 1, b['key']

    a.replace b
    assert_equal 1, a['key']
    a[:key2] = 2
    assert_equal 2, a['key2']
  end
end

