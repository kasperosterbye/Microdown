"
I am the closer delimiter for link name.
"
Class {
	#name : #MicLinkMidwayDelimiter,
	#superclass : #MicAbstractDelimiter,
	#category : #'Microdown-Parser'
}

{ #category : #accessing }
MicLinkMidwayDelimiter class >> associatedInlineBlock [
	^ nil
]

{ #category : #accessing }
MicLinkMidwayDelimiter class >> isCloser [
	^ false
]

{ #category : #accessing }
MicLinkMidwayDelimiter class >> isOpener [
	^ false
]

{ #category : #accessing }
MicLinkMidwayDelimiter class >> markup [
	^ LinkNameCloserMarkup
]
