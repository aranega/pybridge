Class {
	#name : #PyBridgeClass,
	#superclass : #PyBridgeObject,
	#category : #'PyBridge-core'
}

{ #category : #'reflective operations' }
PyBridgeClass >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	self class instanceMap at: self bridgeUUID put: self.
	self post: dict action: #get_class
]

{ #category : #'reflective operations' }
PyBridgeClass >> new [
	^ self new: #()
]

{ #category : #'reflective operations' }
PyBridgeClass >> new: arguments [
	| args dict |
	args := arguments collect: [ :each | self encryptValue: each ].
	dict := {(#args -> args).
	(#clazz -> (self encryptValue: self))} asDictionary.
	^ self decryptAnswer: (self post: dict action: #create_instance)
]

{ #category : #'reflective operations' }
PyBridgeClass >> printString [
	| str res |
	str := self class name asString.
	res := self __str__: self.
	^ str, '(', res literalValue, ')'
]
