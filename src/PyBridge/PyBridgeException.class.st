Class {
	#name : #PyBridgeException,
	#superclass : #Error,
	#instVars : [
		'exceptionClass',
		'arguments'
	],
	#category : #'PyBridge-core'
}

{ #category : #'instance creation' }
PyBridgeException class >> fromClass: aClassSymbol signal: aMessage withArgs: args [
	| exception |
	exception := self new.
	exception exceptionClass: aClassSymbol.
	exception arguments: args.
	exception signal: aMessage.
]

{ #category : #accessing }
PyBridgeException >> arguments [
	^ arguments
]

{ #category : #accessing }
PyBridgeException >> arguments: anObject [
	arguments := anObject
]

{ #category : #accessing }
PyBridgeException >> exceptionClass [
	^ exceptionClass
]

{ #category : #accessing }
PyBridgeException >> exceptionClass: anObject [
	exceptionClass := anObject
]
