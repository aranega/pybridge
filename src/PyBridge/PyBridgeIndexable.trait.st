Trait {
	#name : #PyBridgeIndexable,
	#category : #'PyBridge-characteristics'
}

{ #category : #accessing }
PyBridgeIndexable >> at: anIndex [
	^ self __getitem__: anIndex
]

{ #category : #accessing }
PyBridgeIndexable >> at: anIndex put: anObject [
	^ self __setitem__: anIndex item: anObject 
]
