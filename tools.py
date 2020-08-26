from collections.abc import MutableMapping


class InstanceDict(MutableMapping):
    def __init__(self):
        self.objects_map = {}
        self.reverse_objects_map = {}

    def __delitem__(self, key):
        try:
            instance = self.objects_map[key]
            del self.objects_map[key]
            del self.reverse_objects_map[id(instance)]
        except KeyError:
            instance_id = self.reverse_objects_map[id(key)]
            del self.objects_map[instance_id]
            del self.reverse_objects_map[id(key)]

    def __getitem__(self, key):
        try:
            return self.objects_map[key]
        except Exception:
            return self.__missing__(key)

    def __iter__(self):
        return iter(self.objects_map)

    def __len__(self):
        return len(self.objects_map)

    def __setitem__(self, key, value):
        self.objects_map[key] = value
        py_id = id(value)
        self.reverse_objects_map[py_id] = key

    def __missing__(self, key):
        return self.reverse_objects_map[id(key)]



object_map = InstanceDict()

# o = list()
#
# i = InstanceDict()
#
# i[12] = o
# assert i[12] is o
# assert i[o] is 12
#
# new_id = id(o)
# i.register_alias(12, new_id)
#
# assert i[new_id] is o
