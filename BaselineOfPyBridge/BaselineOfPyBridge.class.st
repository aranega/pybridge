Class {
	#name : #BaselineOfPyBridge,
	#superclass : #BaselineOf,
	#category : #BaselineOfPyBridge
}

{ #category : #baselines }
BaselineOfPyBridge >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec
				repository: 'https//github.com/aranega/pybridge';
				package: 'PyBridge' ]
]

{ #category : #baselines }
BaselineOfPyBridge >> projectClass [
	^ MetacelloCypressBaselineProject
]
