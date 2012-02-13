insensitive_hash
================
Hash with case-insensitive, Symbol/String-indifferent key access.

Installation
------------
```
gem install insensitive_hash
```

Examples
--------

### Instantiation
```ruby
require 'insensitive_hash'

# Monkey-patched Hash#insensitive method
ih = {'abc' => 1, :def => 2}.insensitive

# Or,
ih = InsensitiveHash[ :abc => 1, 'DEF' => 2 ]
ih = InsensitiveHash[ :abc, 1, 'DEF', 2 ]

# Revert to normal Hash
h = ih.sensitive
h = ih.to_hash
```

If you don't like to have Hash#insensitive method, `require 'insensitive_hash/minimal'`

### Basic usage
```ruby
ih = InsensitiveHash[:abc => 1, 'DEF' => 2]

# Case-insensitive, Symbol/String-indifferent access.
ih['Abc']          # 1
ih[:ABC]           # 1
ih['abc']          # 1
ih[:abc]           # 1
ih.has_key?(:DeF)  # true

ih['ABC'] = 10

# keys and values
ih.keys            # ['DEF', 'ABC']
ih.values          # [2, 10]

# delete
ih.delete :Abc     # 10
ih.keys            # ['DEF']
```

### "Inherited insensitivity"
```ruby
# Hash values are recursively converted to be insensitive
# (Useful when processing YAML inputs)
ih = InsensitiveHash.new
ih['kids'] = { :hello => [ { :world => '!!!' } ] }
ih[:kids]['Hello'].first['WORLD']  # !!!

ih['one'] = [ [ [ { :a => { :b => { :c => 'd' } } } ] ] ]
ih['one'].first.first.first['A']['b'][:C]  # 'd'
```

### Processing case-insensitive YAML input
```ruby
db = YAML.load(File.read 'database.yml').insensitive

# Access values however you like
db['Development']['ADAPTER']
db[:production][:adapter]
```

### Replacing spaces in String keys to underscores
```ruby
h = { 'A key with spaces' => true }

ih = h.insensitive :underscore => true
ih[:a_key_with_spaces]  # true
```

## Contributing to insensitive_hash
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Junegunn Choi. See LICENSE.txt for
further details.

