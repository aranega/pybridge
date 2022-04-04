class Example(object):
    def stuff(self, other):
        print("Here")
        # res = other.callback(self)
        res = other()
        res.crLog('Log from Python here what I got as parameter ' + str(other))
        return 42

    def other(self, i):
        print("\nIn Python\n", i)
        return 123
