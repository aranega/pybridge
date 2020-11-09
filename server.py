import flask
from flask import request
import inspect
from tools import InstanceDict
import types
from builtins import list
import sys
import importlib
import json

from tools import object_map


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




@app.route("/<object_id>", methods=["POST"])
def hello(object_id):
    change = request.json
    from pprint import pprint
    pprint(change)
    frame = inspect.currentframe()
    fun = frame.f_globals[change["action"]]
    del change["action"]
    try:
        instance = fun(**change)
        print("Result", instance)
        if fun in (get__dict__, ):
            return instance
        res = build_response(instance)
        pprint(res)
        return res
    except Exception as e:
        return build_exception(e)


def build_exception(e):
    print("Exception", e)
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
    if isinstance(o, bytes):
        return {"kind": "literal", "value": o.decode('utf-8')}
    if is_primitive(o):
        return {"kind": "literal", "value": o}
    if o not in object_map:
        print('registering', o, id(o))
        object_map[id(o)] = o
    if isinstance(o, type):
        print('Its a type', object_map[o])
        return {"kind": "type", "value": {"object_id": object_map[o]}}
    return {"kind": "object", "value": {"object_id": object_map[o]}}


def get__dict__(object_id):
    o = object_map[object_id]
    return {k : build_response(v) for k, v in o.items()}


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
        try:
            return getattr(module, class_name)
        except Exception:
            return importlib.import_module(str)
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


def create_instance(object_id, class_name=None, clazz=None, args=None, nonexisting=False):
    if class_name:
        class_name = class_name.replace("::", ".")
        clazz = str_to_class(class_name)
    else:
        clazz = decrypt(clazz)
        class_name = clazz.__name__
    if isinstance(args, dict):
        instance = clazz(**args)
    else:
        instance = clazz(*args) if args else clazz()
    if nonexisting:
        object_map[id(instance)] = instance
    else:
        object_map[object_id] = instance

    print("Create", class_name, object_id)
    return instance


def instance_setattr(object_id, key, value):
    instance = object_map[object_id]
    if isinstance(value, dict):
        value = decrypt(value)
    key = key[:-1] if key[-1] == ":" else key
    fun = getattr(instance, key, None)
    if callable(fun):
        return fun(decrypt(value))
    setattr(instance, key, value)
    print("Set", key, value)


translation_map = {
    "+": "__add__",
    "-": "__sub__",
    "/": "__truediv__",
    "*": "__mul__",}


def instance_getattr(object_id, key):
    instance = object_map[object_id]
    dict = {"object_id": object_id}
    key = translation_map.get(key, key)
    value = getattr(instance, key)
    if callable(value) and not isinstance(value, type) and not inspect.ismodule(instance):
        # print("I will consider this a callable")
        value = value()
    return value


def decrypt(o):
    try:
        if isinstance(o, dict) and "object_id" in o:
            return object_map[o["object_id"]]
    except Exception:
        print('Problem here, I dont know the object, I put a PharoObject instead')
        from obj import decrypt_answer
        o = decrypt_answer({'kind': o['kind'], 'value': o})
        return o
    return o


def instance_call(object_id, key, args=None):
    import inspect
    args = args or []
    instance = object_map[object_id]
    dict = {"object_id": object_id}
    key = translation_map.get(key, key)
    keys = key.split(":")
    funname = keys[0]
    fun = getattr(instance, funname)

    first_key = next(iter(inspect.signature(fun).parameters), None)
    if first_key:
        keys[0] = first_key
    keywords = {k: decrypt(v) for k, v in zip(keys, args) if k}
    if len(keywords) == 0:
        return fun()
    try:
        return fun(**keywords)
    except TypeError:
        return fun(*keywords.values())


# a = create_instance(1, 'A')
# instance_call(1, 'addition:j:', [1, 2])


def instance_delete(object_id):
    try:
        instance = object_map[object_id]
        del object_map[object_id]
        print("Deleting", object_id, instance)
    except Exception:
        print("Object", object_id, "does not exist anymore, instance from a previous session?")


def flaskThread():
    app.run()


class MethodWrap(object):
    def __init__(self, method):
        self.method = method

    def flushCache(self):
        return self

    def methodClass(self, aMethodClass):
        return self

    def origin(self):
        return getattr(self, "class")

    def package(self):
        return self

    def pragmas(self):
        return []

    def selector(self, aSymbol):
        return self

    def run(self, oldSelector, with_, in_):
        print("IN FAKE METHOD WRAPPER")
        print(oldSelector, with_, in_)
        self.method.__call__(in_, *with_)


def myfoo(self):
    print(self.val)
    self.val = 66

# mymethod = MethodWrap(myfoo)

import obj
from obj import PharoBridge as pharo
from obj import PharoLiteral as literal


class MyTranscript(object):
    @staticmethod
    def show(s):
        print('\n'*4, "InPython!!", s, '\n'*4)


if __name__ == '__main__':
    # from werkzeug.serving import run_simple
    # import _thread as thread
    # thread.start_new_thread(flaskThread,())
    app.run(debug=False, threaded=True)
