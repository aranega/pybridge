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

{ #category : #accessing }
PyBridgeIndexable >> len [
	^ self __len__
]

{ #category : #accessing }
PyBridgeIndexable >> size [
	^ self __len__ value
]
