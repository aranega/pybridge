require 'sinatra'
require 'json'
require './utils.rb'

# $objects_register = {}
# $NIL_OBJECT = {'kind': 'nil_object'}

$objects_register = get_register
$NIL_OBJECT = get_nilobject

def get_register
  $objects_register
end

class A
    def foo
      puts 'in foo'
    end
end

post '/:objectId' do
  data = JSON.parse request.body.read
  action = data['action']
  p data
  data.delete 'action'
  result = __send__(action.to_sym, *data.values)
  build_response(result).to_json
end

def register_literal(value, object_id)
  $objects_register[object_id] = value
  $objects_register[value.object_id] = value
  p $objects_register
  value
end

def instance_call(key, args = nil, object_id)
  o = $objects_register[object_id]
  p $objects_register
  print 'Find object '
  p o
  if key.include? ':'
    key = key.slice(0..(key.index(':') - 1))
    p key
  end
  o.__send__(key.to_sym, *args)
end

def instance_setattr(value, key, object_id)
  instance_call(key, [value], object_id)
end

def instance_getattr(value, object_id)
  instance_call(value, nil, object_id)
end

def class_from_string(str)
  str.split('::').inject(Object) do |mod, class_name|
    mod.const_get(class_name)
  end
end

def get_class(class_name, object_id)
  cls = class_from_string(class_name)
  register_literal(cls, object_id)
end

def instance_delete(object_id)
  puts "We will delete #{object_id}"
  o = $objects_register[object_id]
  keys = $objects_register.select{|key, val| val == o}
  keys.each {|k| $objects_register.delete(k)}
  p $objects_register
  return o
end

def register_object(python_id, object_id)
  o = $objects_register[python_id]
  $objects_register[object_id] = o
  return o
end

def build_response(o)
  if o.nil?
    return $NIL_OBJECT
  elsif o.is_a?(Integer) || o.is_a?(String) || o.is_a?(Symbol) || o.is_a?(TrueClass) || o.is_a?(FalseClass)
    return {'kind': 'literal', 'value': o}
  end
  if ! $objects_register.has_value? o
    $objects_register[o.object_id] = o
  end
  if o.is_a?(Class)
    return {'kind': 'type', 'value': {'object_id': o.object_id}}
  end

  return {'kind': 'object', 'value': {'object_id': o.object_id}}
end
