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

Banana = "[(", AttributeName, ")", "]", "=", '"', DartExpression ;
WhiteSpace = " " | "\t" | "\n" | "\r" ;
Letter = [a-zA-Z] ;
Digit = [0-9] ;
Fragment = (Digit | Letter)+ ;
StartFragment = Letter, [Fragment] ;

/// A TagName identifies HTML elements and components.
///
/// Uppercase letters are converted to lowercase by the parser.
TagName = StartFragment, [ "-", Fragment ]* ;

// Does it make sense to distinguish between Tags and Components?
Node = VoidTag | OpenTag, [Node]*, CloseTag | Comment ;
OpenTag = "<", TagName, Whitespace+, [Attribute, Whitespace+]*, ">" ;
VoidTag = "<", TagName, Whitespace+, [Attribute, Whitespace+]*, "/>" ;
CloseTag = "</", TagName, Whitespace*, ">" ;
Comment = "<!--", [Text]+ , "-->"


/// An AttributeName with added restrictions from HTML.
///
/// In order to make the grammar of directives less ambiguous,
/// There is an added restriction of the characters '*', '[', ']'
/// '(', ')', and '#'.
AttributeName = [^"`'//=\t\n\r \(\)\[\]\*#]+
AttributeValue = '"', Text+, '"'

Attribute = Normal | Structural | Input | Event | Banana | Binding ;
Normal = AttributeName | AttributeName, "=", AttributeValue ;
Structural = "*", AttributeName, "=", (QuotedDartExpression | StructuralExpression);
Input = "[", AttributeName, "]=", QuotedDartExpression ;
Event = "(", AttributeName, ")=", QuotedDartExpression ;
Banana = "[(", AttributeName, ")]=", QuotedDartExpression ;
Binding = "#", AttributeName ;

Text = (RawText | Interpolation)* ;
Interpolation = "{{", QuotedDartExpression , "}}" ;

Text = ... everything but /, <, {{ ;


QuotedDartExpression = '"', 'Dart without double quotes?', '"';
```
