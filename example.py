class Example(object):
    def __init__(self):
        pass

    def stuff(self, other):
        print("Here")
        # res = other.callback(self)
        res = other(self)
        res.crLog('called From python ' + str(other))
        return 42

    def other(self, i):
        print("\nIn Pytho\n", i)
        return 123
