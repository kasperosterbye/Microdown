"
Inline parser rewrite
"
Class {
	#name : #MicInlineParser2,
	#superclass : #Object,
	#instVars : [
		'inlineStream',
		'peekedDelimiter',
		'escapeStack'
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

{ #category : #'parsing-internal' }
MicInlineParser2 >> atOpenerOr: delimiter [
	"return openingDelimiter or nil."
	| allBeginDelimiters maxOpenerLength peek |
	allBeginDelimiters := self class allDelimiters select: #isOpener.
	delimiter ifNotNil: [ allBeginDelimiters at: delimiter markup put: delimiter ].
	maxOpenerLength := (allBeginDelimiters keys collect: #size )max.
	peek := inlineStream peek: maxOpenerLength.
	"try long delimiters before short ones"
	[ peek isEmpty  ]
		whileFalse: [ 
			allBeginDelimiters at: peek ifPresent: [:delim | ^ delim].
			peek := peek allButLast].
	^ nil
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> escapeDecode: aString [
	^ self class escapeReescape: aString except: escapeStack
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> escapePop [
	escapeStack removeLast
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> escapePush: markup [
	escapeStack addLast: markup first
]

{ #category : #'parsing public' }
MicInlineParser2 >> parse: aString [
	"return a ordered collection of children by parsing aString"
	inlineStream := ReadStream on: (self class escapeEncode: aString).
	escapeStack := OrderedCollection new.
	^ self parseEndAt: nil
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseAnchorReference [
	self shouldBeImplemented.
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseAnnotation [
	| body arguments extensionBlock tag |
	MicAnnotationOpenerDelimiter markup size timesRepeat: [ inlineStream next ].
	body := self class 
		escapeReescape:  ( self seekToCloser: MicAnnotationCloserDelimiter markup )
		except: ''.
	MicAnnotationCloserDelimiter markup size timesRepeat: [ inlineStream next ].
	arguments := MicArgumentList
		            split: body
		            defaultArg: #annotationKind
		            defaultValue: 'Me'.
	tag := arguments defaultValue trimBoth.
	extensionBlock := MicAnnotationBlock  extensionClassFor: tag.
	^ extensionBlock new
		substring: body;
		arguments: arguments
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseBold [
	| boldChildren |
	MicBoldDelimiter markup size timesRepeat: [ inlineStream next ].
	boldChildren := self parseEndAt: MicBoldDelimiter.
	MicBoldDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicBoldFormatBlock new
		children: boldChildren 
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> parseEndAt: endDelimiter [
	"return a ordered list of children of this node, fail if not ending with delimeter"
	| children |
	children := OrderedCollection new.
	[ inlineStream atEnd ] whileFalse: [
		"Check for plain text node, and find nested opener or  if any"
		(self seekToOpenenerOr: endDelimiter) 
			ifNotNil: [ :string | children add: (self textNodeFor: string) ].
		"if the delimiter was the end delimiter we are done"
		(peekedDelimiter = endDelimiter) 
			ifTrue: [ ^ children ].
		"If we reached the end without finding endDelimiter, signal an error"
		inlineStream atEnd 
			ifTrue: [ MicParsingError signal ].
		"we found a new opener, and parse nestedBlock"
		children add: self parseNestedBlock].
	^ children
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseFigure [
	| children url split title|
	MicFigureNameOpenerDelimiter  markup size timesRepeat: [ inlineStream next ].
	children := self parseEndAt: MicLinkMidwayDelimiter.
	url := self parseUrl.
	split := url splitOnFirst: Character space.
	title := (split second ifNil: [ '' ]) 
		trimBoth: [:char | {$". Character space} includes: char].
	^ MicFigureBlock new
		url: url;
		reference: (MicResourceReference fromUri: split first);
		arguments: (MicArgumentList withString: title);
		children: children.
		
	
	
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseHttp [
	| body |
	MicHttpDelimiter markup size timesRepeat: [ inlineStream next ].
	body := MicHttpDelimiter markup, (self class 
		escapeReescape:  ( self seekToCondition: [ :c | c isSeparator  ] )
		except: '').
	^ MicLinkBlock new
		url: body;
		reference: (MicResourceReference fromUri: body);
		arguments: (MicArgumentList withString: '');
		children: {MicTextBlock new substring: body}.
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseHttps [
	| body |
	MicHttpsDelimiter markup size timesRepeat: [ inlineStream next ].
	body := MicHttpsDelimiter markup, (self class 
		escapeReescape:  ( self seekToCondition: [ :c | c isSeparator  ] )
		except: '').
	^ MicLinkBlock new
		url: body;
		reference: (MicResourceReference fromUri: body);
		arguments: (MicArgumentList withString: '');
		children: {MicTextBlock new substring: body}.
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseInlineMath [
	| mathBody |
	MicMathDelimiter markup size timesRepeat: [ inlineStream next ].
	mathBody := self class 
		escapeReescape:  ( self seekToCloser: MicMathDelimiter markup )
		except: '$'.
	MicMathDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicMathInlineBlock new
		substring: mathBody.
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseItalics [
	| boldChildren |
	MicItalicDelimiter markup size timesRepeat: [ inlineStream next ].
	boldChildren := self parseEndAt: MicItalicDelimiter.
	MicItalicDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicItalicFormatBlock new
		children: boldChildren 
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseLink [
	| children url split title|
	MicLinkOpenerDelimiter markup size timesRepeat: [ inlineStream next ].
	children := self parseEndAt: MicLinkMidwayDelimiter.
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
MicInlineParser2 >> parseMonospace [
	| monoBody |
	MicMonospaceDelimiter markup size timesRepeat: [ inlineStream next ].
	monoBody := self class 
		escapeReescape:  ( self seekToCloser: MicMonospaceDelimiter markup )
		except: '`'.
	MicMonospaceDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicMonospaceFormatBlock  new
		substring: monoBody.
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> parseNestedBlock [
	"return the a new node corresponding to the newly peeked delimiter"
	| position markup block |
	position := inlineStream position.
	markup := peekedDelimiter markup.
	self escapePush: markup.
	"parseInline: is first step of a double dispatch pattern. 
	Second step brings back to methods in block parsing protocol"
	[ block := peekedDelimiter parseInline: self]
		"If an error occour, we recover by restarting after the opener"
		on: Error
		do: [ inlineStream position: position + markup size.
			 block := (self textNodeFor: markup)].
	self escapePop.
	block children do: [:ch | ch parent: block].
	^ block
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseRaw [
	| body |
	MicRawOpenerDelimiter markup size timesRepeat: [ inlineStream next ].
	body := self class 
		escapeReescape:  ( self seekToCloser: MicRawCloserDelimiter markup )
		except: ''.
	MicRawCloserDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicRawBlock new
		substring: body.
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseStrike [
	| children |
	MicStrikeDelimiter markup size timesRepeat: [ inlineStream next ].
	children := self parseEndAt: MicStrikeDelimiter.
	MicStrikeDelimiter markup size timesRepeat: [ inlineStream next ].
	^ MicStrikeFormatBlock new
		children: children 
]

{ #category : #'block parsing' }
MicInlineParser2 >> parseUrl [
	| body |
	MicLinkMidwayDelimiter markup size timesRepeat: [ inlineStream next ].
	body := self seekToCloser: MicURLCloserDelimiter markup.
	MicURLCloserDelimiter markup size timesRepeat: [ inlineStream next ].
	^ body
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> seekToCloser: closingMarkup [
	"read inlineStream upto first delimiter"
	| buffer peekLength |
	buffer := WriteStream on: ''.
	peekLength := closingMarkup size.
	peekedDelimiter := nil.
	[ inlineStream atEnd or: [(inlineStream peek: peekLength) = closingMarkup ]  ]
		whileFalse: [ buffer nextPut: inlineStream next ].
	^ buffer contents
	
	
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> seekToCondition: block [
	"read inlineStream upto first char which make block evaluate to true"
	| buffer  |
	buffer := WriteStream on: ''.
	peekedDelimiter := nil.
	[ inlineStream atEnd or: [ block value: inlineStream peek]  ]
		whileFalse: [ buffer nextPut: inlineStream next ].
	^ buffer contents
	
	
]

{ #category : #'parsing-internal' }
MicInlineParser2 >> seekToOpenenerOr: delimiter [
	"read inlineStream upto first delimiter"
	| buffer|
	buffer := WriteStream on: ''.
	peekedDelimiter := nil.
	[ inlineStream atEnd or: [(peekedDelimiter := self atOpenerOr: delimiter ) isNotNil ]  ]
		whileFalse: [ buffer nextPut: inlineStream next ].
	^ buffer contents
	
	
]

{ #category : #'node creation' }
MicInlineParser2 >> textNodeFor: string [
	^ MicTextBlock new substring: (self escapeDecode: string).
]
