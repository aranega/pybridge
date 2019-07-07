Class {
	#name : #BaselineOfPyBridge,
	#superclass : #BaselineOf,
	#classVars : [
		'instanceMap'
	],
	#category : #'PyBridge-baseline'
}

{ #category : #baselines }
BaselineOfPyBridge >> baseline: spec [
	<baseline>
	spec for: #common do: [ spec package: 'PyBridge' ]
]

{ #category : #baselines }
BaselineOfPyBridge >> projectClass [
	^ MetacelloCypressBaselineProject
]
