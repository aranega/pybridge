# pybridge
A bridge to call Python from Pharo (only POC at the moment)


## Installation

### Pharo part

```smalltalk
Metacello new
	baseline: 'PyBridge';
	repository: 'github://aranega/pybridge/src';
	load
```


### Python part

The python code is located in the `python` branch.
The project had been built using `pipenv`. Simply checkout in the `python` branch and do:

```
$ pipenv install
```

## Usage

### Python part

You need to launch the server that will be listening for orders from Pharo.
Simply checkout to the `python` branch and run the following command:

```
$ pipenv shell
(pybridge) $ python server.py
```

### Pharo part

You can create objects of a dedicated Python type in Pharo using the `PyBridgeObject` class.
For example, you can open a playground and type:

```smalltalk
myobject := PyBridgeObject new createInstance: #A.  "A here is a class from the server, it's only a test class"
myobject myval.  "Returns a PyBridgeObjectLiteral with the value 0"

otherObject := PyBridgeObject new createInstance: #A.  "Creates another A object"
myobject myref: otherObject.  "Links the two object instances"

myobject myref.  "Returns otherObject"
```

!! Careful, this API will change and evolved.
It's use here simply as a POC.

## Examples

Here are some examples that show how to interact with Python from Pharo using PyBridge.

In this example, a python `list` is created, elements are put inside.
We then iterate on the collection and show elements in the `Transcript`.

```smalltalk
list := PyBridge load: #builtins::list.  "could have been also #'builtins.list'"
mylist := list new.
mylist append: 3.
mylist extend: #(4 5 6 7).
mylist do: [ :each | Transcript crShow: each asString ].
```

In this example, a shortcut is used to create an instance of a Python dictionary.
Then, few values are added inside and we iterate over each keys and values printing them in `Transcript`.

```smalltalk
mydict := PyBridge createInstance: #builtins::dict.
mydict at: #k1 put: 'value1'.
mydict at: #k2 put: 2.
mydict items do: [:tuple | Transcript crShow: '(', (tuple at: 0) value, ',', (tuple at: 1) value asString, ')'].
```

Here, we compile and disassemble some Python code.

```smalltalk
builtins := PyBridge load: #builtins.
disModule := PyBridge load: #dis.

codeObject := builtins compile: 'x = 0' filename: 'testcompile' mode: 'exec'.
(disModule Bytecode: codeObject) do: [ :each | Transcript crShow: each opname asString ].
```

This example opens and write a String into a file.

```smalltalk
builtins := PyBridge loadClass: #builtins.

file := builtins open: 'test.myfile' mode: #w.
file with: [ :f | f write: 'test' ].
```
