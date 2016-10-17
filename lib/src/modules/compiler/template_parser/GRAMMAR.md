#TODO:
* Resolve ambiguities regarding what characters are allowed in different kinds of text blocks (possibly splitting them up).
* Specify what features of HTML are not supported.
* Including missing grammar elements.
* What is Banana formally known as?

```dart
Whitespace = " " | "\t" | "\n" | "\r" ;

// Upper case letters are lowercased
AsciiLetter = "a" | ... | "Z" ;

TagFragment = AsciiLetter+ ;

TagName = TagFragment, [ "-" TagFragment]* ;

AttributeName = // TODO - there are lots of things that are allowed attribute names that maybe we don't want to... ;

RawText = (Text | Interpolation)* ;

Text = ... everything but /, <, {{ ;

Interpolation = "{{", DartExpression , "}}" ;

DartExpression = // TODO ;

Tag = TagSelfClosing | TagOpen, [RawText | Tag+ | Comment], TagClose ;

TagOpen = "<", TagName, Whitespace+, [Attribute, Whitespace]*, ">" ;

TagSelfClosing = "<", TagName, Whitespace+, [Attribute, [Whitespace]+]* , "/>" ;

TagClose = "</", TagName, Whitespace*, ">" ;

Comment = "<!--", [Text]+ , "-->"

Attribute = Normal | Structural | Input | Output | Banana | Binding ;

Normal = AttributeName | AttributeName, "=", AttributeValue ;

// Not sure about this one.
AttributeValue = '"', RawText , '"' ;

Structural = "*", AttributeName, "=", '"', (DartExpression | NgForExpression), '"' ;

Input = "[", AttributeName, "]", "=", '"', DartExpression ;

Output= "(", AttributeName, ")", "=", '"', DartExpression ;

Banana = "[(", AttributeName, ")", "]", "=", '"', DartExpression ;

Binding = "#", AttriubteName ;
```
