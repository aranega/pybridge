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
	arguments ifEmpty: [ ^ self newFromDict: arguments ].
	((arguments at: 1) isKindOf: Association) ifTrue: [ ^ self newFromDict: arguments ].
	^ self newFromList: arguments.
]

{ #category : #private }
PyBridgeClass >> newFromDict: arguments [
	| args dict |
	args := Dictionary new.
	arguments
		do: [ :item | args at: item key put: (self encryptValue: item value) ].
	dict := {(#args -> args).
	(#clazz -> (self encryptValue: self)).
	(#nonexisting -> true)} asDictionary.
	^ self class decryptAnswer: (self post: dict action: #create_instance)
]

{ #category : #private }
PyBridgeClass >> newFromList: arguments [
	| args dict |
	args := arguments collect: [ :item | self encryptValue: item ].
	dict := {(#args -> args asArray).
	(#clazz -> (self encryptValue: self)).
	(#nonexisting -> true)} asDictionary.
	^ self class decryptAnswer: (self post: dict action: #create_instance)
]

{ #category : #'reflective operations' }
PyBridgeClass >> printString [
	| str res |
	str := self class name asString.
	res := self __str__: self.
	^ str, '(', res literalValue, ')'
]
