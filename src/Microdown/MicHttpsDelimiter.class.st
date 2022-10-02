Class {
	#name : #MicHttpsDelimiter,
	#superclass : #MicAbstractDelimiter,
	#category : #'Microdown-Parser'
}

{ #category : #testing }
MicHttpsDelimiter class >> isOpener [
	^ true
]

{ #category : #accessing }
MicHttpsDelimiter class >> markup [
	^ 'https://'
]

{ #category : #parsing }
MicHttpsDelimiter class >> parseInline: inlineParser [
	^ inlineParser parseHttps
]
