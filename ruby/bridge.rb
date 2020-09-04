require 'rest-client'
require './utils.rb'
require 'json'

$objects_register = get_register
$NIL_OBJECT = get_nilobject

class Bridge
  @cls
  def initialize(cls)
    @cls = cls
  end

  def load(name)
    @cls.new().load(name)
  end

  def load(name)
    o = @cls.new()
    loadreq = {'action': 'get_class', 'class_name': name}
    clazz = o.call loadreq
    # p clazz
    $objects_register[clazz['value']['object_id']] = o
    $objects_register[o.id] = o
    o
  end
end

class BridgeObject
  @client
  @url
  @port
  def initialize(url: '127.0.0.1', port: '5000')
    @url = url
    @port = port
    @client = RestClient
  end

  def id
    self.object_id
  end

  def call(payload)
    payload["object_id"] = self.id
    # puts "Calling #@url:#@port/#{self.id} with #{payload}"
    r = @client.post("#@url:#@port/#{self.id}", payload.to_json,  {content_type: :json, accept: :json})
    JSON.parse(r.body)
  end

  def method_missing(name, *args, &block)
    call = {action: :instance_call, key: name.to_sym}
    if args.empty?
      call[:action] = :instance_getattr
    else
      call[:args] = []
    end
    decrypt_answer(self.call(call), self.class)
  end

  def to_s
    v = self.__str__
    "#{v.value}"
  end
end

class PythonObject < BridgeObject
  def initialize
    super(port: 5000)
  end

  def related_class
    PythonClass
  end
  def self.related_class
    PythonClass
  end
  def self.related_object
    PythonObject
  end
  def self.related_literal
    PythonLiteral
  end

  def method_missing(name, *args, **keywords, &block)
    encrypted_args = args.collect {|each| encrypt_object(each)}
    if ! args.empty? && keywords.empty?
      name = "#{name}:".to_sym
    end
    if ! keywords.empty?
      name = "#{name}:" + keywords.keys.collect {|k| "#{k}:"}.join
      encrypted_args += keywords.values.collect {|each| encrypt_object(each)}
    end
    call = {action: :instance_call, key: name, args: encrypted_args}
    # p call
    decrypt_answer(self.call(call), self.class)
  end
end

class PharoObject < BridgeObject
  def initialize
    super(port: 4321)
  end

  def related_class
    PharoClass
  end
  def self.related_class
    PharoClass
  end
  def self.related_object
    PharoObject
  end
  def self.related_literal
    PharoLiteral
  end

  def method_missing(name, *args, **keywords, &block)
    encrypted_args = args.collect {|each| encrypt_object(each)}
    if ! args.empty? && keywords.empty?
      name = "#{name}:".to_sym
    end
    if ! keywords.empty?
      name = "#{name}:" + keywords.keys.collect {|k| "#{k}:"}.join
      encrypted_args += keywords.values.collect {|each| encrypt_object(each)}
    end
    call = {action: :instance_call, key: name, args: encrypted_args}
    # p call
    decrypt_answer(self.call(call), self.class)
  end

  def to_s
    v = self.printString
    "#{v.value}"
  end
end

class PythonClass < PythonObject
  def self.related_object
    PythonObject
  end
  def self.related_class
    PythonClass
  end
  def self.related_literal
    PythonLiteral
  end

  def new
    self.__call__
  end
end

class PharoClass < PharoObject
  def self.related_object
    PharoObject
  end
  def self.related_class
    PharoClass
  end
  def self.related_literal
    PharoLiteral
  end
end

class PythonLiteral < PythonObject
  @value
  def initialize(value)
    super()
    @value = value
    $objects_register[self.id] = self
    self.call({action: :register_literal, value: value})
  end

  def value
    @value
  end
end

class PharoLiteral < PharoObject
  @value
  def initialize(value)
    super()
    @value = value
    $objects_register[self.id] = self
    self.call({action: :register_literal, value: value})
  end

  def value
    @value
  end

  def to_s
    "#{self.value}"
  end
end

$pharo = Bridge.new(PharoClass)
$python = Bridge.new(PythonClass)

def decrypt_answer(d, from)
  # p d
  if d.is_a? Hash
    return __send__("decrypt_#{d['kind']}".to_sym, d, from)
  end
  decrypt_literal({'value': d}, from)
end

def decrypt_object(d, from)
  id = d['value']['object_id']
  o = $objects_register[id]
  if o.nil?
    o = from.related_object.new()
    $objects_register[id] = o
    o.call({python_id: id, action: :register_object})
  end
  o
end

def decrypt_nil_object(d, from)
  return nil
end

def decrypt_literal(d, from)
  value = d['value']
  if value.nil?
    value = d[:value]
  end
  o = from.related_literal.new(value)
  return o
end

def decrypt_exception(d, from)
  puts 'Caught exception'
  p d
end

def decrypt_type(d, from)
  id = d['value']['object_id']
  o = $objects_register[id]
  if o.nil?
    o = from.related_class.new()
    $objects_register[id] = o
    o.call({python_id: id, action: :register_object})
  end
  o
end


def encrypt_object(o)
  # p o
  if o.nil?
    return $NIL_OBJECT
  elsif o.is_a?(Integer) || o.is_a?(String) || o.is_a?(Symbol) || o.is_a?(TrueClass) || o.is_a?(FalseClass)
    return o
  end
  if ! $objects_register.has_value? o
    $objects_register[o.object_id] = o
  end
  if o.is_a?(Class)
    return {'object_id': o.object_id}
  end

  return {'object_id': o.object_id}
end
