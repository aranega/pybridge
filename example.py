class Example(object):
    def stuff(self, other):
        print("Here")
        # res = other.callback(self)
        res = other()
        res.crLog('From Python here is the executed method' + str(other))
        return 42

    def other(self, i):
        print("\nIn Pytho\n", i)
        return 123
