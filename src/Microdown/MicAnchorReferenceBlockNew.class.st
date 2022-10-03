Class {
	#name : #MicAnchorReferenceBlockNew,
	#superclass : #MicInlineElement,
	#instVars : [
		'reference'
	],
	#category : #'Microdown-ModelInline'
}

{ #category : #testing }
MicAnchorReferenceBlockNew class >> isEvaluated [
	^ false
]

{ #category : #visiting }
MicAnchorReferenceBlockNew >> accept: aVisitor [
 	^ aVisitor visitAnchorReference: self
]

{ #category : #visiting }
MicAnchorReferenceBlockNew >> closingDelimiter [

 	^ AnchorReferenceCloserMarkup
]

{ #category : #initialization }
MicAnchorReferenceBlockNew >> kind [

	^ #anchorReference
]

{ #category : #visiting }
MicAnchorReferenceBlockNew >> openingDelimiter [

 	^ AnchorReferenceOpenerMarkup
]

{ #category : #accessing }
MicAnchorReferenceBlockNew >> reference [
	^ reference
]

{ #category : #accessing }
MicAnchorReferenceBlockNew >> reference: aReference [
	reference := aReference
]

{ #category : #visiting }
MicAnchorReferenceBlockNew >> referenceAsHTML [	
	| ref |
	self flag: #todo.
	ref := self reference.
	(ref endsWith: '.mic')
		ifTrue: [ ref := (ref copyUpToLast: $.) , '.html' ]
		ifFalse: [ Error signal: 'Reference : ' , ref , ' should end with .pillar or .pier' ].
	^ ref
]
