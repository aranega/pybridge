Class {
	#name : #PyBridgeObjectLiteral,
	#superclass : #PyBridgeObject,
	#instVars : [
		'literalValue'
	],
	#classInstVars : [
		'literalValue'
	],
	#category : #'PyBridge-core'
}

{ #category : #'instance creation' }
PyBridgeObjectLiteral class >> with: aLiteral [
	| instance dict |
	instance := self new literalValue: aLiteral; yourself.
	dict := { #value -> aLiteral } asDictionary .
	instance post: dict action: #register_literal.
	^ instance
]

{ #category : #accessing }
PyBridgeObjectLiteral >> asNativeObject [
	^ literalValue 
]

{ #category : #accessing }
PyBridgeObjectLiteral >> convertToNativeObject [
	^ literalValue
]

{ #category : #accessing }
PyBridgeObjectLiteral >> literalValue [
	^ literalValue
]

{ #category : #accessing }
PyBridgeObjectLiteral >> literalValue: anObject [
	literalValue := anObject
]

{ #category : #accessing }
PyBridgeObjectLiteral >> printString [
	| str |
	str := self class name asString.
	^ str, '(', literalValue asString, ')'
]

{ #category : #accessing }
PyBridgeObjectLiteral >> value [
	^ literalValue 
]
