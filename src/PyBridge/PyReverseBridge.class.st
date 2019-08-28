Class {
	#name : #PyReverseBridge,
	#superclass : #Object,
	#instVars : [
		'server',
		'instanceMap'
	],
	#classInstVars : [
		'server'
	],
	#category : #'PyBridge-core'
}

{ #category : #accessing }
PyReverseBridge >> decodeValue: anObject [
	anObject isDictionary ifFalse: [ ^ anObject ].
	^ self instanceMap at: (anObject at: #object_id)
]

{ #category : #accessing }
PyReverseBridge >> deleteInstance: objectId [
	| instance |
	[ instance := self instanceMap removeKey: objectId.
	self instanceMap keysAndValuesRemove: [ :k :v | v == instance ] ]
		on: Exception
		do: [ ^ nil ].
	^ nil
]

{ #category : #accessing }
PyReverseBridge >> encryptClass: aClass [
	^ {(#kind -> #type).
	(#value -> {(#object_id -> (self objectId: aClass))} asDictionary)}
		asDictionary
]

{ #category : #accessing }
PyReverseBridge >> encryptLiteral: aLiteral [
	^ {(#kind -> #literal).
	(#value -> aLiteral)} asDictionary
]

{ #category : #accessing }
PyReverseBridge >> encryptNil [
	^ {(#kind -> #nil_object)} asDictionary
]

{ #category : #accessing }
PyReverseBridge >> encryptObject: anObject [
	^ {(#kind -> #object).
	(#value -> {(#object_id -> (self objectId: anObject))} asDictionary)}
		asDictionary
]

{ #category : #accessing }
PyReverseBridge >> encryptValue: anObject [
	anObject isNil ifTrue: [ ^ self encryptNil ].
	anObject isLiteral
		"ifTrue: [ ^ self encryptLiteral: anObject ]."
		ifTrue: [ ^ anObject ].
	anObject isClass
		ifTrue: [ ^ self encryptClass: anObject ].
	^ self encryptObject: anObject
]

{ #category : #accessing }
PyReverseBridge >> instanceCall: key on: objectId [
	| instance res |
	instance := self instanceMap
		at: objectId.
	res := instance perform: key.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : #accessing }
PyReverseBridge >> instanceCall: key on: objectId withArg: anObject [
	| instance res |
	instance := self instanceMap
		at: objectId.
	res := instance perform: key withArguments: (self decodeValue: anObject).
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : #accessing }
PyReverseBridge >> instanceCall: key on: objectId withArgs: aDict [
	| instance res newKey |
	instance := self instanceMap
		at: objectId.
	newKey := ('' join: (aDict keys)) asSymbol. 
	res := instance perform: newKey withArguments: aDict values.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : #accessing }
PyReverseBridge >> instanceCall: key on: objectId withArgs: aDict orderedAs: aDictOrder [
	| instance res newKey keyList newArgs |
	instance := self instanceMap at: objectId.
	keyList := OrderedCollection new.
	1 to: aDictOrder size do: [ :i | keyList add: (aDictOrder at: i asString) ].
	newKey := ('' join: keyList) asSymbol.
	newArgs := keyList collect: [ :e | self decodeValue: (aDict at: e) ].
	res := instance perform: newKey withArguments: newArgs asArray.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : #accessing }
PyReverseBridge >> instanceMap [
	^ instanceMap ifNil: [ instanceMap := Dictionary new ].
]

{ #category : #accessing }
PyReverseBridge >> loadClass: className from: objectId [
	| class |
	class := Smalltalk at: (className asSymbol).
	self instanceMap at: (self objectId: class) ifAbsentPut: [ class ].
	self instanceMap at: (objectId) ifAbsentPut: [ class ].
	^ self encryptValue: class
]

{ #category : #accessing }
PyReverseBridge >> objectId: anObject [
	^ anObject identityHash 
]

{ #category : #accessing }
PyReverseBridge >> registerLiteral: literal on: pythonId [
	self instanceMap at: pythonId put: literal.
	^ pythonId
]

{ #category : #accessing }
PyReverseBridge >> registerObject: objectId on: pythonId [	
	| instance |
	instance := self instanceMap at: objectId.
	self instanceMap at: pythonId put: instance.
	^ pythonId
]

{ #category : #accessing }
PyReverseBridge >> registerRoutes [
	server
		POST:
			'/<obid>'
				-> [ :req | 
					| action result entity |
					entity := STONJSON fromString: req entity string.
					action := entity at: #action.
					action = 'instance_call'
						ifTrue: [ result := (entity includesKey: #args)
								ifFalse: [ self
										instanceCall: (entity at: #key) asSymbol
										on: (entity at: #object_id) ]
								ifTrue: [ (entity includesKey: #order)
										ifTrue: [ self
												instanceCall: (entity at: #key) asSymbol
												on: (entity at: #object_id)
												withArgs: (entity at: #args)
												orderedAs: (entity at: #order) ]
										ifFalse: [ self
												instanceCall: (entity at: #key) asSymbol
												on: (entity at: #object_id)
												withArg: (entity at: #args) ] ] ].
					action = 'get_class'
						ifTrue: [ result := self
								loadClass: (entity at: #class_name)
								from: (req at: #obid) asInteger ].
					action = 'register_object'
						ifTrue: [ result := self
								registerObject: (entity at: #python_id)
								on: (entity at: #object_id) ].
					action = 'instance_delete'
						ifTrue: [ result := self deleteInstance: (entity at: #object_id) ].
					action = 'register_literal'
						ifTrue: [ result := self
								registerLiteral: (entity at: #value)
								on: (entity at: #object_id) ].
					result ]
]

{ #category : #accessing }
PyReverseBridge >> server [
	^ server
]

{ #category : #accessing }
PyReverseBridge >> start [
	server := Teapot
		configure:
			{(#defaultOutput -> #json).
			(#debugMode -> true).
			(#port -> 4321)}.
	server start.
	self registerRoutes
]

{ #category : #accessing }
PyReverseBridge >> stop [
	server stop
]
