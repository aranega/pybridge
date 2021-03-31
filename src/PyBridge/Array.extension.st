Extension { #name : #Array }

{ #category : #'*PyBridge' }
Array >> asNativeObject [
	^ self collect: [ :val | val convertToNativeObject ]
]

{ #category : #'*PyBridge' }
Array >> convertToNativeObject [
	^ self collect: [ :val | val convertToNativeObject ]
]
