Class {
	#name : #PyBridge,
	#superclass : #Object,
	#category : #'PyBridge-core'
}

{ #category : #'reflective operations' }
PyBridge class >> createInstance: aClassSymbol [
	^ PyBridgeObject new createInstance: aClassSymbol
]

{ #category : #'reflective operations' }
PyBridge class >> flushInstances [
	PyBridgeObject instanceMap removeAll
]

{ #category : #'reflective operations' }
PyBridge class >> load: aClassSymbol [
	"Ask for a class in the remote environment"
	^ PyBridgeClass new loadClass: aClassSymbol.
]

{ #category : #'reflective operations' }
PyBridge class >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"
	^ PyBridgeClass new loadClass: aClassSymbol.
]
