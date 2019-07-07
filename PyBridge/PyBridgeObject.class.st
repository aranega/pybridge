Class {
	#name : #PyBridgeObject,
	#superclass : #Object,
	#classVars : [
		'instanceMap'
	],
	#category : #PyBridge
}

{ #category : #'reflective operations' }
PyBridgeObject >> at: anIndex [
	| dict |
	dict := {(#args -> {anIndex}).
	(#key -> #__getitem__)} asDictionary.
	^ self decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : #'reflective operations' }
PyBridgeObject >> bridgeUUID [
	^ self identityHash 
]

{ #category : #'reflective operations' }
PyBridgeObject >> createInstance: aClassSymbol [
	"Ask for an instances creation to the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	instanceMap at: self bridgeUUID put: self.
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> createInstance: aClassSymbol args: anArray [
	"Ask for an instances creation to the remote environment with args"

	| dict |
	dict := {(#class_name -> aClassSymbol).
	(#args -> anArray)} asDictionary.
	instanceMap at: self bridgeUUID put: self.
	self post: dict action: #create_instance
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptAnswer: aZNResponse [
	| dict |
	dict := STONJSON fromString: aZNResponse contents.
	(dict at: #kind) = 'literal'
		ifTrue: [ ^ self decryptLiteral: dict ].
	(dict at: #kind) = 'object'
		ifTrue: [ ^ self decryptObject: dict ]
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptLiteral: aDict [
	| value |
	value := aDict at: #value.
	^ PyBridgeObjectLiteral with: value.
]

{ #category : #'reflective operations' }
PyBridgeObject >> decryptObject: aDict [
	| object json_object object_id |
	json_object := aDict at: #value.
	object_id := json_object at: #object_id.
	object := instanceMap
		at: object_id
		ifAbsentPut: [ | new_object dict |
			new_object := self class new.
			instanceMap at: object_id put: new_object.
			instanceMap at: self identityHash put: new_object.
			dict := {(#python_id -> object_id)} asDictionary.
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
	
	^ { #object_id -> aValue identityHash } asDictionary 
]

{ #category : #'reflective operations' }
PyBridgeObject >> finalize [
	"Ask for a clean of the object in the remote environement"
	self post: (Dictionary new) action: #instance_delete
	
]

{ #category : #'reflective operations' }
PyBridgeObject >> initialize [
	WeakRegistry default add: self. 
	instanceMap := WeakValueDictionary new.
]

{ #category : #'reflective operations' }
PyBridgeObject >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	instanceMap at: self bridgeUUID put: self.
	self post: dict action: #get_class
]

{ #category : #'reflective operations' }
PyBridgeObject >> post: dict action: action [
	| object_id |
	object_id := self bridgeUUID .
	dict at: #object_id put: object_id.
	dict at: #action put: action.
	^ ZnEasy
		post: 'http://127.0.0.1:5000/' , object_id asString
		data:
			(ZnEntity
				with: (STONJSON toString: dict)
				type: ZnMimeType applicationJson)
]
