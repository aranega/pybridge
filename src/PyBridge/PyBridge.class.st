Class {
	#name : #PyBridge,
	#superclass : #Object,
	#classInstVars : [
		'builtins'
	],
	#category : #'PyBridge-core'
}

{ #category : #'reflective operations' }
PyBridge class >> builtins [
	^ builtins := builtins ifNil: [ self load: #builtins ]
]

{ #category : #'reflective operations' }
PyBridge class >> createInstance: aClassSymbol [
	^ PyBridgeObject new createInstance: aClassSymbol
]

{ #category : #'reflective operations' }
PyBridge class >> createInstance: aClassSymbol args: anArray [
	^ PyBridgeObject new createInstance: aClassSymbol args: anArray
]

{ #category : #'reflective operations' }
PyBridge class >> flushInstances [
	PyBridgeObject instanceMap removeAll
]

{ #category : #'reflective operations' }
PyBridge class >> isRunning [
	| reverseServer |
	reverseServer := PyBridgeObject reverseServer.
	^ reverseServer isNotNil and: [ reverseServer isRunning ]
]

{ #category : #'reflective operations' }
PyBridge class >> load: aClassSymbol [
	"Ask for a class in the remote environment"
	self isRunning ifFalse: [ self restart ].
	^ PyBridgeClass new loadClass: aClassSymbol.
]

{ #category : #'reflective operations' }
PyBridge class >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"
	self isRunning ifFalse: [ self restart ].
	^ PyBridgeClass new loadClass: aClassSymbol.
]

{ #category : #'reflective operations' }
PyBridge class >> restart [
	self stop.
	self start
]

{ #category : #'reflective operations' }
PyBridge class >> start [
	| server |
	server := PyBridgeObject reverseServer.
	server
		ifNil: [ server := PyReverseBridge new.
			PyBridgeObject reverseServer: server ].
	^ server start
]

{ #category : #'reflective operations' }
PyBridge class >> stop [
	"PyBridgeObject removeServer"

	| reverseServer |
	reverseServer := PyBridgeObject reverseServer.
	reverseServer
		ifNotNil: [ reverseServer stop.
			reverseServer flushInstances ].
	self flushInstances
]
