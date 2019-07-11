import flask
from flask import request
import inspect
from tools import InstanceDict
import types
from builtins import list
import sys
import importlib


class A(object):
    def __init__(self, val=0):
        self.myval = val

    def test(self):
        return self.myval

    def addition(self, i, j):
        self.myval += i + j
        return self.myval

    def hello(self, message='hello', number=None):
        print('From hello', message, number.myval)
        return number

    def myself(self):
        return self


from flask import Flask

app = Flask(__name__)


object_map = InstanceDict()


@app.route("/<object_id>", methods=["POST"])
def hello(object_id):
    change = request.json
    frame = inspect.currentframe()
    fun = frame.f_globals[change["action"]]
    del change["action"]
    try:
        instance = fun(**change)
        print("Result", instance)
    except Exception as e:
        return build_exception(e)
    return build_response(instance)


def build_exception(e):
    return {
        "kind": "exception",
        "class": e.__class__.__name__,
        "args": e.args,
    }


primitive = (int, str, bool, float)


def is_primitive(o):
    return isinstance(o, primitive)


NIL_OBJECT = {"kind": "nil_object"}


def build_response(o):
    response = {}
    if o is None:
        return NIL_OBJECT
    if is_primitive(o):
        return {"kind": "literal", "value": o if o is not None else NIL_OBJECT}
    if o not in object_map:
        print('registering', o, id(o))
        object_map[id(o)] = o
    if isinstance(o, type):
        print('Its a type', object_map[o])
        return {"kind": "type", "value": {"object_id": object_map[o]}}
    return {"kind": "object", "value": {"object_id": object_map[o]}}


def register_literal(object_id, value):
    object_map[object_id] = value
    return value


def register_object(object_id, python_id):
    o = object_map[python_id]
    object_map[object_id] = o
    object_map.reverse_objects_map[python_id] = object_id
    print('register', object_id, 'for', o, 'on', python_id)
    return python_id


def str_to_class(str):
    if "." in str:
        segments = str.split(".")
        module = ".".join(segments[:-1])
        class_name = segments[-1]
        module = importlib.import_module(module)
        return getattr(module, class_name)
    try:
        return getattr(sys.modules[__name__], str)
    except Exception:
        return importlib.import_module(str)


def get_class(object_id, class_name):
    class_name = class_name.replace("::", ".")
    clazz = str_to_class(class_name)
    object_map[object_id] = clazz
    print('get_class', object_id, id(clazz))
    return clazz


def create_instance(object_id, class_name, args=None):
    class_name = class_name.replace("::", ".")
    clazz = str_to_class(class_name)
    instance = clazz(*args) if args else clazz()
    object_map[object_id] = instance

    print("Create", class_name, object_id)
    return instance


def instance_setattr(object_id, key, value):
    instance = object_map[object_id]
    if isinstance(value, dict):
        value = object_map[value["object_id"]]
    key = key[:-1] if key[-1] == ":" else key
    fun = getattr(instance, key, None)
    if callable(fun):
        return fun(decrypt(value))
    setattr(instance, key, value)
    print("Set", key, value)


translation_map = {"+": "__add__", "-": "__sub__", "/": "__truediv__"}


def instance_getattr(object_id, key):
    instance = object_map[object_id]
    dict = {"object_id": object_id}
    key = translation_map.get(key, key)
    value = getattr(instance, key)
    if callable(value) and not isinstance(value, type):
        print("callable")
        value = value()
    return value


def decrypt(o):
    if isinstance(o, dict) and "object_id" in o:
        return object_map[o["object_id"]]
    return o


def instance_call(object_id, key, args=None):
    args = args or []
    instance = object_map[object_id]
    dict = {"object_id": object_id}
    key = translation_map.get(key, key)
    keys = key.split(":")
    keywords = {k: decrypt(v) for k, v in zip(keys, args) if k}
    key = keys[0]

    fun = getattr(instance, key)
    first = keywords.pop(key, None)
    if first is None:
        return fun()
    try:
        return fun(first, **keywords)
    except TypeError:
        return fun(first, *keywords.values())


# a = create_instance(1, 'A')
# instance_call(1, 'addition:j:', [1, 2])


def instance_delete(object_id):
    try:
        instance = object_map[object_id]
        del object_map[object_id]
        print("Deleting", object_id, instance)
    except Exception:
        print("Object", object_id, "does not exist anymore")


app.run()
