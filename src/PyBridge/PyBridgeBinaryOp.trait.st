Trait {
	#name : #PyBridgeBinaryOp,
	#category : #'PyBridge-characteristics'
}

{ #category : #arithmetic }
PyBridgeBinaryOp >> * another [
	^ self __mult__: another
]

{ #category : #arithmetic }
PyBridgeBinaryOp >> + another [
	^ self __add__: another
]
