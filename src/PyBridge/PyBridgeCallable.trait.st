Trait {
	#name : #PyBridgeCallable,
	#category : #'PyBridge-characteristics'
}

{ #category : #'as yet unclassified' }
PyBridgeCallable >> call [
	^ self __call__
]
