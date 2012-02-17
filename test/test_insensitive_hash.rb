require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)
require 'test/unit'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'insensitive_hash/minimal'

class TestInsensitiveHash < Test::Unit::TestCase
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

    assert_equal ['A'], ih.keys
    assert_equal [2], ih.values

    ih[:A] = 4
    assert_equal ih.keys, [:A]
    assert_equal [:A], ih.keys
    assert_equal [4], ih.values

    ih[:b] = { :c => 5 }
    assert          ih.keys.include?(:A)
    assert          ih.keys.include?(:b)
    assert_equal 2, ih.keys.length
    assert_equal({ :c => 5 }, ih['B'])
    assert_equal 5, ih['B']['C']

    ih['c'] = [ { 'x' => 1 }, { :y => 2 } ]
    assert       ih.keys.include?('c')
    assert_equal 3, ih.keys.length
    assert_equal 1, ih[:c].first[:x]
    assert_equal 2, ih[:c].last['Y']

    # Deeeeeper nesting
    ih['c'] = [ [ [ { 'x' => 1 }, { :y => 2 } ] ] ]
    assert_equal 2, ih[:c].first.first.last[:Y]
    ih['c'] = { 'a' => { 'a' => { 'a' => 100 } } }
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

    assert_raise(NoMethodError) {
      hash.insensitive
    }

    require 'insensitive_hash'
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

    # InsensitiveHash#insensitive
    ihash1 = hash.insensitive
    ihash1.default = :default
    ihash1.underscore = true
    ihash2 = ihash1.insensitive.insensitive.insensitive

    assert_equal InsensitiveHash, ihash2.class
    assert_equal :default, ihash2.default
    assert_equal true,     ihash2.underscore?

    # Preserving default
    [:default, nil].each do |d|
      hash.default = d
      assert_equal d, hash.insensitive.insensitive.insensitive[:anything]
    end

    # Preserving default_proc
    hash2 = {}
    hash2.replace hash
    hash2.default_proc = proc { |h, k| h[k] = :default }

    ihash2 = hash2.insensitive.insensitive.insensitive
    assert !ihash2.has_key?(:anything)
    assert_equal :default, ihash2[:anything]
    assert ihash2.has_key?(:anything)

    # FIXME: test insensitive call with encoder
    h = InsensitiveHash[{'Key with spaces' => 1}]
    h2 = h.insensitive :underscore => true
    h3 = h.insensitive :underscore => false
    assert_raise(ArgumentError) { h.insensitive :underscore => :wat }

    assert_equal 1, h['key with spaces']
    assert_nil      h[:key_with_spaces]
    assert_equal 1, h3['key with spaces']
    assert_nil      h3[:key_with_spaces]
    assert_equal 1, h2[:KEY_WITH_SPACES]
    assert_equal 1, h2[:Key_with_spaces]

    assert_equal ['Key with spaces'], h.keys
    assert_equal ['Key with spaces'], h2.keys
    assert_equal ['Key with spaces'], h3.keys

    h = { 'A key with spaces' => true }
    ih = h.insensitive :underscore => true
    assert ih[:a_key_with_spaces]
    assert ih.underscore?

    # FIXME: from README
    ih = InsensitiveHash[ h ]
    ih.underscore = true
    assert ih[:a_key_with_spaces]
    assert ih.underscore?
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

      assert_equal [:a, 'hello world'], ih.keys
      assert_equal [:a, 'hello world', :b], ih2.keys
      assert ih2.has_key?('B'), 'correctly merged another hash'

      assert_nil ih[:hello_world]
      assert_nil ih2[:hello_world]

      ih.underscore = true
      assert_equal 2, ih[:hello_world]
      assert_equal 2, ih.send(method, :b => 2)[:hello_world]

      ih.underscore = false
      assert_nil ih[:hello_world]
      assert_nil ih.send(method, :b => 2)[:hello_world]

      ih.default = 10
      assert_equal 10, ih.send(method, :b => 2)[:anything]

      ih.default = nil
      assert_nil ih.send(method, :b => 2)[:anything]

      ih.default_proc = proc { |h, k| h[k] = :default }
      mh = ih.send(method, :b => 2)
      assert       !mh.has_key?(:anything)
      assert_equal :default, mh[:anything]
      assert        mh.has_key?(:anything)

      ih2.delete 'b'
      assert ih2.has_key?('B') == false
    end
  end

  def test_merge!
    [:merge!, :update!].each do |method|
      ih = InsensitiveHash[:a => 1]
      ih2 = ih.send(method, :b => 2)

      assert_equal [:a, :b], ih.keys
      assert_equal [:a, :b], ih2.keys
      assert ih2.has_key?('B'), 'correctly merged another hash'

      ih2.delete 'b'
      assert ih2.has_key?('B') == false
    end
  end

  def test_merge_clash_overwritten
    ih = InsensitiveHash.new

    ih = ih.merge(:a => 1, :A =>2)
    assert_equal 2, ih.values.first
    assert_equal 2, ih['A']
    assert_equal 1, ih.length

    ih = InsensitiveHash.new
    ih.underscore = true
    ih.merge!(:hello_world => 1, 'hello world' =>2)
    assert_equal 2, ih.values.first
    assert_equal 2, ih[:Hello_World]
    assert_equal 1, ih.length
  end

  def test_merge_clash
    ih = InsensitiveHash.new
    ih2 = InsensitiveHash.new
    ih2.underscore = true

    sih = InsensitiveHash.new
    sih.safe = true
    sih2 = InsensitiveHash.new
    sih2.safe = true
    sih2.underscore = true

    [:merge, :merge!, :update, :update!].each do |method|
      # No problem
      [ih, ih2].each do |h|
        h.send(method, { :a => 1, :A => 1, 'A' => 1})
        h.send(method, { 'a' => 1, 'A' => 1 })
      end

      [sih, sih2].each do |h|
        assert_raise(InsensitiveHash::KeyClashError) {
          h.send(method, { :a => 1, :A => 1, 'A' => 1})
        }
        assert_raise(InsensitiveHash::KeyClashError) {
          h.send(method, { 'a' => 1, 'A' => 1 })
        }
      end

      sih.send(method, { :hello_world => 1, 'hello world' => 2})
      assert_raise(InsensitiveHash::KeyClashError) {
        sih2.send(method, { :hello_world => 1, 'hello world' => 2})
      }
      ih2.send(method, { :hello_world => 1, 'hello world' => 2})
    end

    ih.merge({ :a => 1, :A => 1, 'A' => 1})
    assert_raise(InsensitiveHash::KeyClashError) {
      sih.merge({ :a => 1, :A => 1, 'A' => 1})
    }
  end

  def test_assoc
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

  def test_delete_if
    # FIXME: Test passes, but key_map not updated
    h = InsensitiveHash[ :a => 100, :tmp_a => 200, :c => 300 ]
    h.delete_if.each { |k, v| k == :tmp_a }
    assert_equal [:a, :c], h.keys
  end

  def test_has_key_after_delete
    set = [:a, :A, 'a', 'A', :b, :B, 'b', 'B']
    h = InsensitiveHash[ :a => 1, :b => 2 ]
    
    set.each { |s| assert h.has_key?(s) }
    h.delete_if { |e| true }
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

    # underscore property of self
    assert !h.underscore?
    h.replace(InsensitiveHash['hello world' => 1].tap { |ih| ih.underscore = true })
    assert h.underscore?
    assert_equal 1, h[:hello_world]

    # TODO: FIXME
    # underscore property of other
    h = InsensitiveHash.new
    oh = InsensitiveHash[ 'hello world' => 1 ]
    oh.underscore = true
    assert !h.underscore?
    h.replace(oh)
    assert h.underscore?

    oh.underscore = false
    oh[:hello_world => 2]
    h.replace(oh)
    assert !h.underscore?
  end

  def test_rassoc
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
    assert_raise(KeyError) { h.fetch('D') }
  end

  def test_underscore
    h = InsensitiveHash[{'Key with spaces' => 1}]

    assert_equal 1, h['key with spaces']
    assert_nil      h[:key_with_spaces]

    test_keys = [
      :KEY_WITH_SPACES,
      :Key_with_spaces,
      :key_with_spaces,
      'key with_spaces',
      'KEY_WITH spaces'
    ]

    10.times do
      assert_raise(ArgumentError) { h.underscore = 'wat' }
      assert !h.underscore?
      h.underscore = true
      assert h.underscore?

      
      test_keys.each do |k|
        assert_equal 1, h[k]
      end
      assert_equal ['Key with spaces'], h.keys

      h.underscore = false
      assert !h.underscore?
      assert_equal 1, h['KEY WITH SPACES']
      test_keys.each do |k|
        assert_nil h[k]
      end
      assert_equal ['Key with spaces'], h.keys
    end

    h.underscore = true
    test_keys.each do |tk|
      h[tk] = 1
    end

    assert_equal [test_keys.last], h.keys
  end

  def test_underscore_inheritance
    h = InsensitiveHash[
      {
        'Key with spaces' => {
          'Another key with spaces' => 1
        },
        'Key 2 with spaces' =>
          InsensitiveHash['Yet another key with spaces' => 2].tap { |ih| ih.underscore = true },
        'Key 3 with spaces' =>
          InsensitiveHash['Yet another key with spaces' => 3]
      }
    ]

    assert_equal 1,     h['key with spaces']['another key with spaces']
    assert_equal false, h['key with spaces'].underscore?
    assert_nil          h['key with spaces'][:another_key_with_spaces]
    assert_nil          h[:key_with_spaces]

    assert_equal 2, h['key 2 with spaces']['yet another key with spaces']
    assert_equal 2, h['key 2 with spaces'][:yet_another_key_with_spaces]
    assert_nil      h[:key_2_with_spaces]

    assert_equal 3, h['key 3 with spaces']['yet another key with spaces']
    assert_nil      h['key 3 with spaces'][:yet_another_key_with_spaces]
    assert_nil      h[:key_3_with_spaces]

    h.underscore = true
    assert_equal true, h[:key_with_spaces].underscore?
    assert_equal 1,    h[:key_with_spaces][:another_key_with_spaces]
    assert_equal true, h[:key_2_with_spaces].underscore?
    assert_equal 2,    h[:key_2_with_spaces][:yet_another_key_with_spaces]
    assert_equal true, h[:key_3_with_spaces].underscore?
    assert_equal 3,    h[:key_3_with_spaces][:yet_another_key_with_spaces]

    h.underscore = false
    assert_nil h[:key_with_spaces]
    assert_nil h[:key_2_with_spaces]
    assert_nil h[:key_3_with_spaces]

    assert_equal false, h.underscore?
    assert_equal true,  h['key 2 with spaces'].underscore?
    assert_equal true,  h['key 3 with spaces'].underscore?
  end

  def test_underscore_clash
    h = InsensitiveHash.new
    h.safe = true

    h['hello world'] = 1
    h['HELLO_world'] = 2
    assert_equal 1, h['HELLO WORLD']
    assert_equal 2, h['HELLO_WORLD']
    assert_equal ['hello world', 'HELLO_world'], h.keys

    assert_raise(InsensitiveHash::KeyClashError) { h.underscore = true }
    h.delete('hello world')
    h.underscore = true

    assert_equal ['HELLO_world'], h.keys
    assert_equal 2, h['HELLO WORLD']
    assert_equal 2, h[:HELLO_WORLD]
  end

  def test_unset_underscore
    h = InsensitiveHash.new
    h.underscore = true
    h[:hello_world] = 1
    h.underscore = false
    h['hello world'] = 2

    assert_equal [:hello_world, 'hello world'], h.keys
    assert_equal 2, h['Hello World']
  end
end

