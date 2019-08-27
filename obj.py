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
        print('key', key)
        return BridgeDelayObject(self, key, self.session)

    def __call__(self, *args, **kwargs):
        print("Calling!")


    def call(self, data):
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=data)
        return answer.json()

    def __str__(self):
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': 'asString'
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
            'object_id': self.id_
        }
        clazz = self.call(loadreq)
        object_map[clazz["value"]["object_id"]] = self
        return self

    def __call__(self, *args, **kwargs):
        print("Creating instance of a class")
        req = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': 'new',
        }
        return decrypt_answer(self.call(req))


class BridgeLiteral(BridgeObject):
    def __init__(self, value, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.value = value

    def __add__(self, other):
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': '+'
        }
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=change)
        left = decrypt_answer(answer.json())
        left.__add__()

        return decrypt_answer(answer.json())


class BridgeDelayObject(object):
    def __init__(self, instance, key, session):
        self.instance = instance
        self.key = key
        self.session = session

    @property
    def id_(self):
        return self.instance.id_

    def __call__(self, *args, **kwargs):
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': self.key,
            'args': None
        }
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=change)
        return decrypt_answer(answer.json())

    def __getattr__(self, key):
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': self.key
        }
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=change)
        return decrypt_answer(answer.json(), delay_key=key)

    def __add__(self, other):
        print(f'Addition no call, SEND ATTRIBUTE ASKING {self.key}')
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': self.key
        }
        myid = self.id_
        print(myid)
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=change)
        left = decrypt_answer(answer.json())
        left.__add__(other)
        return decrypt_answer(answer.json())

    def __str__(self):
        print(f'str no call, SEND ATTRIBUTE ASKING {self.key}')
        change = {
            'action': 'instance_call',
            'object_id': self.id_,
            'key': self.key
        }
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4321/{myid}", data=change)
        left = decrypt_answer(answer.json())
        return left.__str__()


def decrypt_answer(d, delay_key=None):
    return decrypt_map[d["kind"]](d, delay_key)

def decrypt_literal(d, delay_key):
    res = BridgeLiteral(d["value"])
    if delay_key:
        return BridgeDelayObject(res, delay_key, res.session)
    return res

def decrypt_object(d, delay_key):
    object_id = d["value"]["object_id"]
    if object_id not in object_map:
        o = BridgeObject()
        object_map[object_id] = o
        req ={
            'python_id': o.id_,
            'action': 'register_object',
            'object_id': object_id,
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
