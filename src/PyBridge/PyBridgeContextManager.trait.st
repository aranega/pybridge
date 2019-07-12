Trait {
	#name : #PyBridgeContextManager,
	#category : #'PyBridge-characteristics'
}

{ #category : #manager }
PyBridgeContextManager >> with: aBlock [
	| element |
	element := self __enter__.
	aBlock value: element.
	element __exit__: 0 exc_val: 0 exc_tb: 0.
]
