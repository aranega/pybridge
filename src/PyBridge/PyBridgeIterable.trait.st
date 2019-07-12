Trait {
	#name : #PyBridgeIterable,
	#category : #'PyBridge-characteristics'
}

{ #category : #enumerating }
PyBridgeIterable >> do: aBlock [
	self doWithIndex: aBlock
]

{ #category : #enumerating }
PyBridgeIterable >> doWithIndex: aBlock [
	| iterator raisedException i |
	iterator := self __iter__.
	raisedException := false.
	i := 0.
	[ raisedException ]
		whileFalse: [ | element |			
			[ element := iterator __next__.
			aBlock cull: element cull: i.
			i := i + 1]
				on: PyBridgeException
				do: [ :e | e exceptionClass = #StopIteration ifTrue: [ raisedException := true ] ifFalse: [ e signal ] ]  ]
]
