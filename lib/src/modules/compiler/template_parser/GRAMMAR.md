#TODO:
* Resolve ambiguities regarding what characters are allowed in different kinds of text blocks (possibly splitting them up).
* Specify what features of HTML are not supported.
* Including missing grammar elements.
* What is Banana formally known as?

```
WhiteSpace      = " " | "\t" | "\n" | "\r";
Letter          = [a-zA-Z];
Digit           = [0-9];
Fragment        = (Digit | Letter)+;
TagName         = Letter, [Fragment], [ "-", Fragment ]*;
Node            = VoidTag | OpenTag, [Node]*, CloseTag | Comment;
OpenTag         = "<", TagName, WhiteSpace+, [Attribute, WhiteSpace+]*, ">";
VoidTag         = "<", TagName, WhiteSpace+, [Attribute, WhiteSpace+]*, "/>";
CloseTag        = "</", TagName, WhiteSpace*, ">";
Comment         = "<!--", [RawText]+ , "-->";
AttributeName   = [^"`'//=\t\n\r \(\)\[\]\*#]+;
AttributeValue  = '"', Text+, '"';
Attribute       = Normal | Structural | Input | Event | Banana | Binding;
Normal          = AttributeName | AttributeName, "=", AttributeValue;
Structural      = "*", AttributeName, "=", (QuotedDartExpression | StructuralExpression);
Input           = "[", AttributeName, "]=", QuotedDartExpression;
Event           = "(", AttributeName, ")=", QuotedDartExpression;
Banana          = "[(", AttributeName, ")]=", QuotedDartExpression;
Binding         = "#", AttributeName;
Text            = (RawText | Interpolation)* ;
Interpolation   = "{{", QuotedDartExpression , "}}";
QuotedDartExpression = '"', 'Dart without double quotes?', '"';
```
