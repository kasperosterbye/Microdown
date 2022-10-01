"
I am the opener delimiter for link name.
"
Class {
	#name : #MicLinkOpenerDelimiter,
	#superclass : #MicAbstractDelimiter,
	#category : #'Microdown-Parser'
}

{ #category : #accessing }
MicLinkOpenerDelimiter class >> associatedInlineBlock [
	^ MicLinkBlock 
]

{ #category : #accessing }
MicLinkOpenerDelimiter class >> isCloser [
	^ false
]

{ #category : #accessing }
MicLinkOpenerDelimiter class >> isOpener [
	^ true
]

{ #category : #accessing }
MicLinkOpenerDelimiter class >> markup [
	^ LinkNameOpenerMarkup
]

{ #category : #parsing }
MicLinkOpenerDelimiter class >> parseInline: aMicInlineParser [
	^ aMicInlineParser parseLink
]
