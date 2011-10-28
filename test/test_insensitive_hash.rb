require 'rubygems'
require 'test/unit'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'insensitive_hash'

class TestInsensitiveHash < Test::Unit::TestCase
  def test_from_hash
    hash = {
      'a' => 1,
      'B' => 2,
      :c  => { :D => [ { 'e' => 3 } ] }
    }

    [hash.insensitive, InsensitiveHash.new(hash)].each do |ih|
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

  def test_has_key_set
    ih = InsensitiveHash.new
    ih['a'] = 1
    ih['A'] = 2

    ['a', 'A', :a, :A].each do |a|
      assert       ih.has_key?(a)
      assert_equal 2, ih[a]
    end

    assert_equal ['A'], ih.keys
    assert_equal [2], ih.values

    ih[:A] = 4
    assert_equal [:A], ih.keys
    assert_equal [4], ih.values

    ih[:b] = { :c => 5 }
    assert          ih.keys.include?(:A)
    assert          ih.keys.include?(:b)
    assert_equal 2, ih.keys.length
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

  def test_delete
    ih = InsensitiveHash.new(:a => 1)
    assert_equal [:a], ih.keys
    assert_equal [1], ih.values

    assert_equal 1, ih.delete('A')
    assert_equal [], ih.keys
  end
end
