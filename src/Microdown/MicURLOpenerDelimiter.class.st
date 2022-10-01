"
I'm the opener delimiter for URL.
"
Class {
	#name : #MicURLOpenerDelimiter,
	#superclass : #MicAbstractDelimiter,
	#category : #'Microdown-Parser'
}

{ #category : #accessing }
MicURLOpenerDelimiter class >> associatedInlineBlock [
	^ nil
]

{ #category : #testing }
MicURLOpenerDelimiter class >> isActive [
	^ false
]

{ #category : #accessing }
MicURLOpenerDelimiter class >> isCloser [
	^ false
]

{ #category : #accessing }
MicURLOpenerDelimiter class >> isOpener [
	^ true
]

{ #category : #accessing }
MicURLOpenerDelimiter class >> markup [
	^ URLOpenerMarkup
]

{ #category : #parsing }
MicURLOpenerDelimiter class >> parseInline: aMicInlineParser [
	^ aMicInlineParser parseUrl
]

{ #category : #accessing }
MicURLOpenerDelimiter class >> type [
	^ #url
]
