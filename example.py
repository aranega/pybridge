class Example(object):
    def __init__(self):
        pass

    def stuff(self, other):
        print("Here")
        res = other.callback(self)
        return  res + 42

    def other(self, i):
        print("\nIn Pytho\n", i)
        return 42
