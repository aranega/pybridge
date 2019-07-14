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
	| dict |
	dict := {(#key -> #__call__)} asDictionary.
	^ self decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : #'reflective operations' }
PyBridgeClass >> printString [
	| str res |
	str := self class name asString.
	res := self __str__: self.
	^ str, '(', res literalValue, ')'
]
