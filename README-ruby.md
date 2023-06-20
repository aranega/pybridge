# How to use the bridge between Ruby and Python

## Requirements

Ruby:

* sinatra
* rest-client

Python:

* requests

## General information

To use Ruby objects, it's necessary to have all the dependencies installed and the ruby object server running:

```bash
$ cd ruby
$ ruby ./server.rb
```

## Use Ruby objects in Python

To import Ruby objects in Python, you have to import the `rubyobj` module and to importy the bridge:

```python
from rubyobj import RubyBridge as ruby
```

Once you gain access to the bridge, you can now load Ruby classes and uses them as Python classes.
Please note that the support is still very experimental.

```python
from rubyobj import RubyBridge as ruby

Hash = ruby.load('Hash')  # we import the Hash object from Ruby
h = Hash.new()  # We explicitally call "new" (not mandatory) on the loaded class

h['foo'] = 5
print(h)

# displays '{"foo"=>5}', the internal representation displayed by Ruby

print(h['foo'])
# displays 5
```

## Use Python objects in Ruby

To import Python objects in Ruby, first go in the `ruby` directory then, load the bridge file.

```ruby
require './bridge.rb'

A = $python.load 'A'
a = A.new()

print(a.test())
# displays 0=>nil
```
