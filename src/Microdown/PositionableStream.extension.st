Extension { #name : #PositionableStream }

{ #category : #'*Microdown' }
PositionableStream >> peek: anInteger [ 
	"Only works for string based streams"
	^ collection copyFrom: position + 1 to: (position + anInteger min: readLimit)
]
