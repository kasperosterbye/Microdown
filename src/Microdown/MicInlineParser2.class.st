Class {
	#name : #MicInlineParser2,
	#superclass : #Object,
	#instVars : [
		'inlineStream',
		'peekedDelimiter'
	],
	#classVars : [
		'AllDelimiters',
		'KeyBeginSet',
		'Keys'
	],
	#pools : [
		'MicMicrodownSharedPool'
	],
	#category : #'Microdown-Parser'
}

{ #category : #accessing }
MicInlineParser2 class >> abstractDelimiterClass [

	^ MicAbstractDelimiter
]

{ #category : #accessing }
MicInlineParser2 class >> allDelimiters [
	"I return a orderd dictionary of all delimiters. The order is with long named delimiters first"
	AllDelimiters ifNil: [ 
		AllDelimiters := OrderedDictionary new.
		(self abstractDelimiterClass allSubclasses sort: [ :a :b | a size > b size ]) do: [ :subclass | 
				AllDelimiters 
					at: subclass markup 
					put: subclass ] ].

	^ AllDelimiters 
]

{ #category : #'escape character' }
MicInlineParser2 class >> escapeDecode: aString [
	"I convert all encoded chars back to their original (without the leading escape character)"
	"My sister method escapeEncode encodes into the format I decode from"
	| inStream outStream char special |
	aString ifEmpty: [ ^aString ].
	special := [ :c | c asInteger between: self magicCharacter  and: self magicCharacter + 65536 ].
	inStream := ReadStream on: aString.
	outStream := WriteStream on: String new.
	[ inStream atEnd ] whileFalse: [ 
		char := inStream next.
		(special value: char)
			ifTrue: [ char := (char asInteger - self magicCharacter ) asCharacter  ].
		outStream nextPut: char
	].
	^ outStream contents
	
]

{ #category : #'escape character' }
MicInlineParser2 class >> escapeEncode: aString [
	"I convert all escaped characters (eg '\`' or '\\') into special characters which are not used in Microdown"
	"My sister method escapeDecode reverts back"
	| inStream outStream char |
	aString size <= 1 ifTrue: [ ^aString ].
	inStream := ReadStream on: aString.
	outStream := WriteStream on: String new.
	[ inStream atEnd ] whileFalse: [ 
		char := inStream next.
		(char = $\ and: [ inStream atEnd not ]) 
			ifTrue: [ char := (inStream next asInteger + self magicCharacter) asCharacter  ].
		outStream nextPut: char
	].
	^ outStream contents
	
]

{ #category : #'escape character' }
MicInlineParser2 class >> escapeReescape: aString except: keep [
	"I convert all encoded back to escaped chars, except the characters in keep"
	"My sister method escapeEncode encodes into the format I decode from"
	| inStream outStream char |
	aString ifEmpty: [ ^aString ].
	inStream := ReadStream on: aString.
	outStream := WriteStream on: String new.
	[ inStream atEnd ] whileFalse: [ 
		char := inStream next.
		(char asInteger between: self magicCharacter  and: self magicCharacter + 65536)
			ifTrue: [ 
				char := (char asInteger - self magicCharacter ) asCharacter.  
				(keep includes: char) ifFalse: [outStream nextPut: $\]] .
		outStream nextPut: char
	].
	^ outStream contents
	
]

{ #category : #initialization }
MicInlineParser2 class >> initialize [
	<script>
	AllDelimiters := KeyBeginSet := nil.
]

{ #category : #accessing }
MicInlineParser2 class >> keyBeginSet [

	KeyBeginSet ifNil: [ KeyBeginSet := (self allDelimiters keys collect: #first) asSet ].
	^ KeyBeginSet
]

{ #category : #accessing }
MicInlineParser2 class >> keys [

	Keys ifNil: [ KeyBeginSet := (self allDelimiters keys collect: #first) asSet ].
	^ KeyBeginSet
]

{ #category : #'escape character' }
MicInlineParser2 class >> magicCharacter [
	"All escaped characters are moved out of range. 
	The unicode range Private Use Area is used, 
	see https://en.wikipedia.org/wiki/Private_Use_Areas "
	^ 16r100000 "Private Use Area-B"
]

{ #category : #parsing }
MicInlineParser2 >> atBeginDelimiter [
	"return openingDelimiter or nil."
	| allBeginDelimiters maxOpenerLength peek |
	allBeginDelimiters := self class allDelimiters select: #isOpener.
	maxOpenerLength := (allBeginDelimiters keys collect: #size )max.
	peek := inlineStream peek: maxOpenerLength.
	"try long delimiters before short ones"
	[ peek isEmpty  ]
		whileFalse: [ 
			allBeginDelimiters at: peek ifPresent: [:delim | ^ delim].
			peek := peek allButLast].
	^ nil
]

{ #category : #parsing }
MicInlineParser2 >> parse: aString [
	"return a ordered list of children of this node"
	inlineStream := ReadStream on: aString.

	^ self parseEndAt: nil
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseBold [
	| boldChildren |
	MicBoldDelimiter markup size timesRepeat: [ inlineStream next ].
	boldChildren := self parseEndAt: MicBoldDelimiter markup.
	MicBoldDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicBoldFormatBlock new
		children: boldChildren 
]

{ #category : #parsing }
MicInlineParser2 >> parseEndAt: delimiter [
	"return a ordered list of children of this node"
	| children |
	children := OrderedCollection new.
	[ inlineStream atEnd ]
		whileFalse: [
			self seekToDelimiter
				ifNotNil: [ :string | children add: (MicTextBlock new substring:  string)].
			(peekedDelimiter isNotNil and: [ peekedDelimiter markup = delimiter ]) ifTrue: [ ^children ].
			inlineStream atEnd
				ifFalse: [ 
					children add: self parseInlineBlock ]
			 ].
	^ children
]

{ #category : #parsing }
MicInlineParser2 >> parseInlineBlock [
	^ peekedDelimiter parseInline: self
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseItalics [
	| boldChildren |
	MicItalicDelimiter markup size timesRepeat: [ inlineStream next ].
	boldChildren := self parseEndAt: MicItalicDelimiter markup.
	MicItalicDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicItalicFormatBlock new
		children: boldChildren 
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseLink [
	| children url link split title|
	MicLinkNameOpenerDelimiter markup size timesRepeat: [ inlineStream next ].
	children := self parseEndAt: MicLinkNameCloserDelimiter  markup.
	MicLinkNameCloserDelimiter markup size timesRepeat: [ inlineStream next ].
	self seekToDelimiter.
	peekedDelimiter = MicURLOpenerDelimiter ifFalse: [ 
		^ MicTextBlock new substring: '>>> Error - Something went wrong in parsing this link <<<' ].
	url := self parseUrl.
	split := url splitOnFirst: Character space.
	title := (split second ifNil: [ '' ]) 
		trimBoth: [:char | {$". Character space} includes: char].
	^ MicLinkBlock new
		url: url;
		reference: (MicResourceReference fromUri: split first);
		arguments: (MicArgumentList withString: title);
		children: children.
		
	
	
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseUrl [
	| body |
	MicURLOpenerDelimiter markup size timesRepeat: [ inlineStream next ].
	body := self seekTo: MicURLCloserDelimiter markup.
	MicURLCloserDelimiter markup size timesRepeat: [ inlineStream next ].
	^ body
]

{ #category : #parsing }
MicInlineParser2 >> seekTo: closingMarkup [
	"read inlineStream upto first delimiter"
	| buffer peekLength |
	buffer := WriteStream on: ''.
	peekLength := closingMarkup size.
	peekedDelimiter := nil.
	[ inlineStream atEnd or: [(inlineStream peek: peekLength) = closingMarkup ]  ]
		whileFalse: [ buffer nextPut: inlineStream next ].
	^ buffer contents
	
	
]

{ #category : #parsing }
MicInlineParser2 >> seekToDelimiter [
	"read inlineStream upto first delimiter"
	| buffer|
	buffer := WriteStream on: ''.
	peekedDelimiter := nil.
	[ inlineStream atEnd or: [(peekedDelimiter := self atBeginDelimiter) isNotNil ]  ]
		whileFalse: [ buffer nextPut: inlineStream next ].
	^ buffer contents
	
	
]
