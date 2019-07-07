Class {
	#name : #PyBridge,
	#superclass : #Object,
	#category : #'PyBridge-core'
}

{ #category : #'reflective operations' }
PyBridge class >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"
	^ PyBridgeClass new loadClass: aClassSymbol.
]