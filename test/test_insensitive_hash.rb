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
      ih = InsensitiveHash[:a => 1]
      ih2 = ih.send(method, :b => 2)

      assert_equal [:a], ih.keys
      assert_equal [:a, :b], ih2.keys
      assert ih2.has_key?('B'), 'correctly merged another hash'

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
    h = InsensitiveHash[:a, 1]
    assert_equal 1, h[:A]

    h = h.to_hash
    assert_equal Hash, h.class
    assert_equal nil, h[:A]
    assert_equal 1, h[:a]
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

  def test_fetch
    h = InsensitiveHash[{ :a => 1, :b => 2, :c => 3}]
    assert_raise(KeyError) { h.fetch('D') }
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
end

