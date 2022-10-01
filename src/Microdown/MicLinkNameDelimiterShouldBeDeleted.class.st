Class {
	#name : #MicLinkNameDelimiterShouldBeDeleted,
	#superclass : #Object,
	#category : #'Microdown-Parser'
}

{ #category : #accessing }
MicLinkNameDelimiterShouldBeDeleted class >> associatedTypes [

	^ {  
		self type.
		MicFigureNameOpenerDelimiter type.
	}
]

{ #category : #testing }
MicLinkNameDelimiterShouldBeDeleted class >> isActive [

	^ self ~= MicLinkNameDelimiterShouldBeDeleted
]

{ #category : #accessing }
MicLinkNameDelimiterShouldBeDeleted class >> type [

	^ #linkName
]

{ #category : #dispatching }
MicLinkNameDelimiterShouldBeDeleted >> addInlineBlock: anIndex to: inlineParser [

	inlineParser linkOrFigureProcess: anIndex
]
