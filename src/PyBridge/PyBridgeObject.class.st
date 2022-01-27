Class {
	#name : #PyBridgeObject,
	#superclass : #Object,
	#traits : 'PyBridgeIterable + PyBridgeContextManager + PyBridgeIndexable + PyBridgeCallable',
	#classTraits : 'PyBridgeIterable classTrait + PyBridgeContextManager classTrait + PyBridgeIndexable classTrait + PyBridgeCallable classTrait',
	#instVars : [
		'objectId'
	],
	#classVars : [
		'instanceMap',
		'reverseServer'
	],
	#classInstVars : [
		'string2class'
	],
	#category : #'PyBridge-core'
}

{ #category : #'reflective operations' }
PyBridgeObject class >> decryptAnswer: aZNResponse [
	| dict |
	dict := STONJSON fromString: aZNResponse contents.
	^ self decryptPythonElement: dict
]

{ #category : #'reflective operations' }
PyBridgeObject class >> decryptException: aDict [
	PyBridgeException fromClass: (aDict at: #class)  signal: (aDict at: #args) asString withArgs: (aDict at: #args) 
]

{ #category : #'reflective operations' }
PyBridgeObject class >> decryptLiteral: aDict [
	| value |
	value := aDict at: #value.
	^ PyBridgeObjectLiteral with: value.
]

{ #category : #'reflective operations' }
PyBridgeObject class >> decryptObject: aDict [
	| object json_object remote_id |
			
	json_object := aDict at: #value.
	remote_id := json_object at: #object_id.
	object := self instanceMap
		at: remote_id
		ifAbsent: [ | new_object dict |			
			new_object := (self string2class at: (aDict at: #kind)) new.
			self instanceMap at: new_object bridgeUUID put: new_object.
			dict := {(#python_id -> remote_id)} asDictionary.
			new_object post: dict action: #register_object.
			new_object ].
	^ object
]

{ #category : #'reflective operations' }
PyBridgeObject class >> decryptPythonElement: dict [

	dict isArray ifTrue: [ 
		^ dict collect: [ :e | self decryptPythonElement: e ] ].
	dict isDictionary ifFalse: [ ^ dict ].
	dict at: #kind ifAbsent: [ ^ dict "should be recursive" ]. 
	(dict at: #kind) = 'literal' ifTrue: [ ^ self decryptLiteral: dict ].
	(dict at: #kind) = 'object' ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'type' ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'nil_object' ifTrue: [ ^ nil ].
	(dict at: #kind) = 'exception' ifTrue: [ 
		^ self decryptException: dict ]
]

{ #category : #'reflective operations' }
PyBridgeObject class >> instanceMap [
	^ instanceMap := instanceMap ifNil: [ WeakValueDictionary new ]
]

{ #category : #'reflective operations' }
PyBridgeObject class >> removeServer [
	reverseServer ifNil: [ ^ self ]. 
	reverseServer stop.
	reverseServer := nil
]

{ #category : #'reflective operations' }
PyBridgeObject class >> reverseServer [
	^ reverseServer
]

{ #category : #'reflective operations' }
PyBridgeObject class >> reverseServer: aServer [
	reverseServer := aServer
]

{ #category : #testing }
PyBridgeObject class >> string2class [
	^ string2class := string2class
		ifNil: [ {(#object -> PyBridgeObject).
			(#type -> PyBridgeClass)} asDictionary ]
]

{ #category : #'reflective operations' }
PyBridgeObject >> asNativeDict [
	| dict response newDict |
	response := self post: Dictionary new action: #get__dict__.
	dict := STONJSON fromString: response contents.
	newDict := Dictionary new.
	dict
		keysAndValuesDo: [ :key :val | newDict at: key put: (self class decryptPythonElement: val) ].
	^ newDict
]

{ #category : #'reflective operations' }
PyBridgeObject >> asNativeList [
	| result |
	result := OrderedCollection new.
	self do: [ :each | result add: each ].
	^ result
]

{ #category : #'reflective operations' }
PyBridgeObject >> asNativeObject [
	"get__native_object__"

	| struct response |
	response := self post: Dictionary new action: #get__native_object__.
	struct := STONJSON fromString: response contents.
	^ (struct at: 'native') convertToNativeObject
]

{ #category : #'reflective operations' }
PyBridgeObject >> asOrderedCollection [
	| result |
	result := OrderedCollection new.
	self do: [ :each | result add: each ].
	^ result
]

{ #category : #'reflective operations' }
PyBridgeObject >> bridgeUUID [
	^ self bridgeUUIDOf: self   
]

{ #category : #'reflective operations' }
PyBridgeObject >> bridgeUUIDOf: anObject [
	^ anObject identityHash 
]

{ #category : #'reflective operations' }
PyBridgeObject >> convertToNativeObject [
	^ self
]

{ #category : #'reflective operations' }
PyBridgeObject >> createInstance: aClassSymbol [
	"Ask for an instances creation to the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	self instanceMap at: objectId put: self.
	
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> createInstance: aClassSymbol args: anArray [
	"Ask for an instances creation to the remote environment with args"

	| dict |
	dict := {(#class_name -> aClassSymbol).
	(#args -> anArray)} asDictionary.
	self instanceMap at: objectId put: self.
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> doesNotUnderstand: aMessage [
	| dict arg |
	aMessage numArgs = 0
		ifTrue: [ dict := {(#key -> aMessage selector)} asDictionary.
			^ self class decryptAnswer: (self post: dict action: #instance_getattr) ].
	(aMessage numArgs = 1 and: [ aMessage selector isBinary not ])
		ifTrue: [ arg := aMessage argument.
			dict := {(#value -> (self encryptValue: arg)).
			(#key -> aMessage selector)} asDictionary.
			^ self class decryptAnswer: (self post: dict action: #instance_setattr) ].
	^ self performCall: aMessage selector args: aMessage arguments
]

{ #category : #'reflective operations' }
PyBridgeObject >> encryptValue: aValue [
	| id kind |
	aValue isLiteral
		ifTrue: [ ^ aValue ].
	aValue isDictionary
		ifTrue: [ ^ aValue ].
	id := self bridgeUUIDOf: aValue.
	self reverseServerIsRunning ifTrue: [ self reverseServer instanceMap at: id ifAbsentPut: [ aValue ] ].
	aValue isBlock
		ifTrue: [ kind := #block ]
		ifFalse: [ aValue isClass
				ifTrue: [ kind := #type ]
				ifFalse: [ kind := #object ] ].
	^ {(#object_id -> (self bridgeUUIDOf: aValue)).
	(#kind -> kind)} asDictionary
]

{ #category : #'reflective operations' }
PyBridgeObject >> finalize [
	"Ask for a clean of the object in the remote environement"

	[ self post: Dictionary new action: #instance_delete ]
		on: ConnectionTimedOut
		do: [ :ex | self ]
]

{ #category : #'reflective operations' }
PyBridgeObject >> initialize [
	objectId := self bridgeUUID.
	self finalizationRegistry add: self.
]

{ #category : #'reflective operations' }
PyBridgeObject >> instanceMap [
	^ self class instanceMap
]

{ #category : #'reflective operations' }
PyBridgeObject >> performCall: methodName args: arguments [
	| args dict |
	args := arguments collect: [ :each | self encryptValue: each ].
	dict := {(#args -> args).
	(#key -> methodName)} asDictionary.
	^ self class decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : #'reflective operations' }
PyBridgeObject >> performCall: methodName argsDict: arguments [
	| args dict |
	args := (arguments
		collect: [ :entry | entry key -> (self encryptValue: entry value) ])
		asDictionary.
	dict := {(#args -> args).
	(#key -> methodName)} asDictionary.
	^ self decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : #'reflective operations' }
PyBridgeObject >> post: dict action: action [
	dict at: #object_id put: objectId.
	dict at: #action put: action.
	^ ZnEasy
		post: 'http://127.0.0.1:5000/' , objectId asString
		data:
			(ZnEntity
				with: (STONJSON toString: dict)
				type: ZnMimeType applicationJson)
]

{ #category : #'reflective operations' }
PyBridgeObject >> printOn: aStream [

	aStream << self __str__ literalValue
]

{ #category : #'reflective operations' }
PyBridgeObject >> printString [

	^ self __str__ literalValue
]

{ #category : #'spec - inspections' }
PyBridgeObject >> pyBridgeInspection [

	<inspectorPresentationOrder: 1 title: 'Remote raw'>
	| table |
	table := SpTablePresenter new.
	table beResizable.
	table addColumn:
		(SpStringTableColumn title: 'Variable' evaluated: [ :e | e key ]).
	table addColumn: (SpStringTableColumn
			 title: 'Value'
			 evaluated: [ :e | e value printString ]).
	table items: self pyBridgeInspectionSlots.
	^ table
]

{ #category : #'spec - inspections' }
PyBridgeObject >> pyBridgeInspectionSlots [

	| dict elements |
	[ dict := self __dict__ ]
		on: Error
		do: [ :e | 
			^ OrderedCollection with: (PyBridgeObjectInspectorNode new
					   key: 'None';
					   value: 'Object has no __dict__';
					   yourself) ].
	self flag: 'This way of doing things is incorrect: it should be done only if we get a collection. How to make the difference?'.
	elements := OrderedCollection new.
	dict items do: [ :k :v | 
		elements add: ((PyBridgeObjectInspectorNode hostObject: self)
				 key: k;
				 value: v;
				 yourself) ].
	^ elements
]

{ #category : #'reflective operations' }
PyBridgeObject >> reverseServer [
	^ self class reverseServer 
]

{ #category : #'reflective operations' }
PyBridgeObject >> reverseServerIsRunning [
	^ self reverseServer isNotNil and: [ self reverseServer isRunning ]
]
