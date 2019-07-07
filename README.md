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
