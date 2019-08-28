import requests
from server import object_map


class PharoBridge(object):
    @staticmethod
    def load(clazz):
        return BridgeClass().load(clazz)


class BridgeObject(object):
    def __init__(self, id_=None):
        self.id_ = id_ or id(self)
        self.isCalled = False
        self.session = requests.post

    def __getattr__(self, key):
        return BridgeDelayObject(self, key, self.session)

    def __call__(self, *args, **kwargs):
        print("Calling!")


    def call(self, data):
        data["object_id"] = self.id_
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", json=data)
        return answer.json()

    def __str__(self):
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': 'printString'
        }
        return decrypt_answer(self.call(change)).value

    def __del__(self):
        print("Object gc", self.id_)
        try:
            del object_map[self.id_]
        except Exception:
            pass
        delreq = {
            'action': 'instance_delete',
            'object_id': self.id_,
        }
        self.call(delreq)


class BridgeClass(BridgeObject):
    def load(self, name):
        loadreq = {
            'action': 'get_class',
            'class_name': name,
        }
        clazz = self.call(loadreq)
        object_map[clazz["value"]["object_id"]] = self
        return self

    def __call__(self, *args, **kwargs):
        req = {
            'action': 'instance_call',
            'key': 'new',
        }
        return decrypt_answer(self.call(req))

    def __add__(self, other):
        change = {
            'action': 'instance_call',
            'key': '+'
        }
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", json=change)
        left = decrypt_answer(answer.json())
        left.__add__()

        return decrypt_answer(answer.json())


class BridgeLiteral(BridgeObject):
    def __init__(self, value, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.value = value


class BridgeDelayObject(object):
    def __init__(self, instance, key, session):
        self.instance = instance
        self.key = key
        self.session = session

    @property
    def id_(self):
        return self.id_

    def __call__(self, *args, **kwargs):
        change = {
            'action': 'instance_call',
            'key': self.key,
            'args': None
        }
        return decrypt_answer(self.instance.call(change))

    def __getattr__(self, key):
        change = {
            'action': 'instance_call',
            'key': self.key
        }
        return decrypt_answer(self.instance.call(change), delay_key=key)

    def __add__(self, other):
        print(f'Addition no call, SEND ATTRIBUTE ASKING {self.key}')
        change = {
            'action': 'instance_call',
            'key': self.key
        }
        left = decrypt_answer(self.instance.call(change))
        return left.__add__(other)

    def __str__(self):
        # print(f'str no call, SEND ATTRIBUTE ASKING {self.key}')
        change = {
            'action': 'instance_call',
            'key': self.key
        }
        left = decrypt_answer(self.instance.call(change))
        return left.__str__()


def decrypt_answer(d, delay_key=None):
    return decrypt_map[d["kind"]](d, delay_key)

def decrypt_literal(d, delay_key):
    value = d["value"]
    o = BridgeLiteral(value=value)
    if delay_key:
        o = BridgeDelayObject(res, delay_key, res.session)
    object_map[o.id_] = o
    req ={
        'action': 'register_literal',
        'value': value
    }
    o.call(req)
    return o

def decrypt_object(d, delay_key):
    object_id = d["value"]["object_id"]
    if object_id not in object_map:
        o = BridgeObject()
        object_map[object_id] = o
        req ={
            'python_id': object_id,
            'action': 'register_object',
        }
        o.call(req)
        return o
    return object_map[object_id]


decrypt_map = {
    "literal": decrypt_literal,
    "object": decrypt_object,
    "nil_object": lambda x, delay_key=None: None,
}


Point = PharoBridge.load('Point')
# p = Point()

# print(p)
