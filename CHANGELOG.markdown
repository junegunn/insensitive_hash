### 0.2.2 / 2012/02/13
* :underscore option added
* `Insensitive::KeyClashError` added for safer operations
* Bug fix: Preserve default/default_proc on merge/replace/insensitive
* Subtle behavioral change in Insensitive#replace when called with an ordinary Hash

### 0.2.1 / 2012/02/10
* Bug fix: Insensitive `fetch`

### 0.2.0 / 2012/02/01
* Major rewrite
 * Constructor syntaxes have been changed to match those of standard Hash (not backward-compatible)
 * (Almost) Complete implementation of standard Hash spec.

### 0.1.0 / 2011/12/20
* Can opt-out of monkey-patching Hash with `require 'insensitive_hash/minimal'`

### 0.0.2-3 / 2011/10/28
* Removed duplicated code in the constructor
* More tests
