Trait {
	#name : #PyBridgeIterable,
	#category : #'PyBridge-characteristics'
}

{ #category : #enumerating }
PyBridgeIterable >> do: aBlock [
	| iterator raisedException tempNumber iterations |
	iterator := self __iter__.
	raisedException := false.
	tempNumber := aBlock argumentCount.
	iterations := tempNumber - 1.
	[ raisedException ]
		whileFalse: [ | element args |
			[ element := iterator __next__.
			args := OrderedCollection new.
			tempNumber > 1
				ifTrue:
					[ 0 to: iterations do: [ :index | args add: (element at: index) ] ]
				ifFalse: [ args add: element ].
			aBlock valueWithArguments: args ]
				on: PyBridgeException
				do: [ :e | 
					e exceptionClass = #StopIteration
						ifTrue: [ raisedException := true ]
						ifFalse: [ e signal ] ] ]
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
