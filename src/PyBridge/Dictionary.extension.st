Extension { #name : #Dictionary }

{ #category : #'*PyBridge' }
Dictionary >> asNativeObject [
	| newDict isObject |
	isObject := self isDictionary
		and: [ (self includesKey: #kind) and: [ self includesKey: #value ] ].
	isObject
		ifTrue: [ ^ (PyBridgeObject decryptPythonElement: self) convertToNativeObject ].
	newDict := self class new.
	self
		keysAndValuesDo: [ :key :val | newDict at: key put: val convertToNativeObject ].
	^ newDict
]

{ #category : #'*PyBridge' }
Dictionary >> convertToNativeObject [
	| newDict isObject |
	isObject := self isDictionary
		and: [ (self includesKey: #kind) and: [ self includesKey: #value ] ].
	isObject
		ifTrue:
			[ ^ (PyBridgeObject decryptPythonElement: self) convertToNativeObject ].
	newDict := self class new.
	self
		keysAndValuesDo: [ :key :val | newDict at: key put: val convertToNativeObject ].
	^ newDict
]
