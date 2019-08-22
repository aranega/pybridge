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
	self instanceMap at: self bridgeUUID put: self.
	self post: dict action: #get_class
]

{ #category : #'reflective operations' }
PyBridgeClass >> new [
	^ self new: {} asDictionary 
]

{ #category : #'reflective operations' }
PyBridgeClass >> new: arguments [
	| args dict |
	args := Dictionary new.
	arguments
		do: [ :item | args at: item key put: (self encryptValue: item value) ].
	dict := {(#args -> args).
	(#clazz -> (self encryptValue: self)).
	(#nonexisting -> true)} asDictionary.
	^ self decryptAnswer: (self post: dict action: #create_instance)
]

{ #category : #'reflective operations' }
PyBridgeClass >> printString [
	| str res |
	str := self class name asString.
	res := self __str__: self.
	^ str, '(', res literalValue, ')'
]
