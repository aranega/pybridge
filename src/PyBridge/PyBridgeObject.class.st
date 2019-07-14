Class {
	#name : #PyBridgeObject,
	#superclass : #Object,
	#traits : 'PyBridgeIterable + PyBridgeContextManager + PyBridgeIndexable',
	#classTraits : 'PyBridgeIterable classTrait + PyBridgeContextManager classTrait + PyBridgeIndexable classTrait',
	#instVars : [
		'objectId'
	],
	#classInstVars : [
		'instanceMap',
		'string2class'
	],
	#category : #'PyBridge-core'
}

{ #category : #testing }
PyBridgeObject class >> instanceMap [
	^ instanceMap := instanceMap ifNil: [ WeakValueDictionary new ]
]

{ #category : #testing }
PyBridgeObject class >> string2class [
	^ string2class := string2class
		ifNil: [ {(#object -> PyBridgeObject).
			(#type -> PyBridgeClass)} asDictionary ]
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
PyBridgeObject >> createInstance: aClassSymbol [
	"Ask for an instances creation to the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	self class instanceMap at: objectId put: self.
	
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> createInstance: aClassSymbol args: anArray [
	"Ask for an instances creation to the remote environment with args"

	| dict |
	dict := {(#class_name -> aClassSymbol).
	(#args -> anArray)} asDictionary.
	self class instanceMap at: objectId put: self.
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptAnswer: aZNResponse [
	| dict |
	dict := STONJSON fromString: aZNResponse contents.
	(dict at: #kind) = 'literal'
		ifTrue: [ ^ self decryptLiteral: dict ].
	(dict at: #kind) = 'object'
		ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'type'
		ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'nil_object'
		ifTrue: [ ^ nil ].
	(dict at: #kind) = 'exception'
		ifTrue: [ ^ self decryptException: dict ]
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptException: aDict [
	PyBridgeException fromClass: (aDict at: #class)  signal: (aDict at: #args) asString withArgs: (aDict at: #args) 
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptLiteral: aDict [
	| value |
	value := aDict at: #value.
	^ PyBridgeObjectLiteral with: value.
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptObject: aDict [
	| object json_object remote_id |
			
	json_object := aDict at: #value.
	remote_id := json_object at: #object_id.
	object := self class instanceMap
		at: remote_id
		ifAbsent: [ | new_object dict |			
			new_object := (self class string2class at: (aDict at: #kind)) new.
			self class instanceMap at: new_object bridgeUUID put: new_object.
			dict := {(#python_id -> remote_id)} asDictionary.
			new_object post: dict action: #register_object.
			new_object ].
	^ object
]

{ #category : #'reflective operations' }
PyBridgeObject >> doesNotUnderstand: aMessage [
	| dict arg args |
	aMessage numArgs = 0
		ifTrue: [ dict := {(#key -> aMessage selector)} asDictionary.
			^ self decryptAnswer: (self post: dict action: #instance_getattr) ].
	(aMessage numArgs = 1 and: [ aMessage selector isBinary not ])
		ifTrue: [ arg := aMessage argument.
			dict := {(#value -> (self encryptValue: arg)).
			(#key -> aMessage selector)} asDictionary.
			^ self decryptAnswer: (self post: dict action: #instance_setattr) ].
	args := aMessage arguments
		collect: [ :each | self encryptValue: each ].
	dict := {(#args -> args).
	(#key -> aMessage selector)} asDictionary.
	^ self decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : #'reflective operations' }
PyBridgeObject >> encryptValue: aValue [
	aValue isLiteral ifTrue: [ ^ aValue ].
	
	^ { #object_id -> (self bridgeUUIDOf: aValue) } asDictionary
]

{ #category : #'reflective operations' }
PyBridgeObject >> finalize [
	"Ask for a clean of the object in the remote environement"
	self post: (Dictionary new) action: #instance_delete
	
]

{ #category : #'gt-inspector-extension' }
PyBridgeObject >> gtInspectorRemoteObject: composite [
	<gtInspectorPresentationOrder: 50>
	composite table
		title: [ 'Remote raw' translated ];
		display: [ :anObject | 
			| instVars |
			instVars := OrderedCollection new.
			[ anObject __dict__ items
				do: [ :key :val | instVars add: key value -> val ] ]
				on: PyBridgeException
				do: [ instVars add: 'None' -> 'Object has no __dict__' ].
			instVars asArray ];
		column: 'Variable'
			evaluated: [ :assoc | GTObjectPrinter asNonTruncatedTextFrom: assoc key ];
		column: 'Value'
			evaluated: [ :assoc | assoc value printString ]

]

{ #category : #'reflective operations' }
PyBridgeObject >> initialize [
	objectId := self bridgeUUID.
	self finalizationRegistry add: self.
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
PyBridgeObject >> printString [
	| str res |
	str := super printString.
	res := self __str__.
	^ str, '(', res literalValue, ')'
]
