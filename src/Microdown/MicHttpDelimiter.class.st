Class {
	#name : #MicHttpDelimiter,
	#superclass : #MicAbstractDelimiter,
	#category : #'Microdown-Parser'
}

{ #category : #testing }
MicHttpDelimiter class >> isOpener [
	^ true
]

{ #category : #accessing }
MicHttpDelimiter class >> markup [
	^ 'http://'
]

{ #category : #parsing }
MicHttpDelimiter class >> parseInline: inlineParser [
	^ inlineParser parseHttp
]
