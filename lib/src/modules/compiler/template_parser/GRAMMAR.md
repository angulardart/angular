```dart
Whitespace = " " | "\t" | "\n" | "\r" ;

// Upper case letters are lowercased
AsciiLetter = "a" | ... | "Z" ;

TagFragment = AsciiLetter+ ;

TagName = TagFragment, [ "-" TagFragment]* ;

AttributeName = // TODO ;

RawText = // TODO ;

Interpolation = "{{", DartExpression , "}}" ;

DartExpression = // TODO ;

// Tags
Tag = TagSelfClosing | TagOpen, [RawText | Tag+ ], TagClose ;

TagOpen = "<", TagName, Whitespace+, [Attribute, Whitespace]*, ">" ;

TagSelfClosing = "<", TagName, Whitespace+, [Attribute, Whitespace]*, "/>" ;

TagClose = "</", TagName, Whitespace*, ">" ;

// Attributes
Attribute = Normal | Structural | Input | Output | Banana | Binding ;

// TODO: are attributes without values supported?
Normal = AttributeName | AttributeName, "=", AttributeValue ;

// Not sure about this one.
AttributeValue = '"', RawText , '"' ;

Structural = "*", AttributeName, "=", '"', (DartExpression | NgForExpression), '"' ;

Input = "[", AttributeName, "]", "=", '"', DartExpression ;

Output= "(", AttributeName, ")", "=", '"', DartExpression ;

Combined = "[(", AttributeName, ")", "]", "=", '"', DartExpression ;

DartExpression = // TODO ;

NgForExpression = // TODO ;
```
