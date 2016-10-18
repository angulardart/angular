#TODO:
* Resolve ambiguities regarding what characters are allowed in different kinds of text blocks (possibly splitting them up).
* Specify what features of HTML are not supported.
* Including missing grammar elements.
* What is Banana formally known as?

```ebnf
WhiteSpace        = ? all whitespace characters ?;
Letter            = [a-zA-Z];
Digit             = [0-9];
Fragment          = (Digit | Letter)+;
TagName           = Letter, [Fragment], [ "-", Fragment ]*;
Node              = VoidTag | OpenTag, [Node]*, CloseTag | Comment;
OpenTag           = "<", TagName, WhiteSpace+, [Attribute, WhiteSpace+]*, ">";
VoidTag           = "<", TagName, WhiteSpace+, [Attribute, WhiteSpace+]*, "/>";
CloseTag          = "</", TagName, WhiteSpace*, ">";
Comment           = "<!--", [RawText]+ , "-->";
AttributeName     = [^"`'//=\t\n\r \(\)\[\]\*\.#]+;
AttributeValue    = '"', Text+, '"';
Attribute         = Normal | Structural | Input | Event | Banana | Binding;
Normal            = AttributeName | AttributeName, "=", AttributeValue;
Structural        = "*", AttributeName, "=", (DartExpression | StructuralExpression);
Input             = "[", AttributeName [".", AttributeName], "]=", DartExpression;
Event             = "(", AttributeName,  [".", AttributeName], ")=", DartExpression;
Banana            = "[(", AttributeName, ")]=", DartExpression;
Binding           = "#", AttributeName;
Text              = (RawText | Interpolation)* ;
Interpolation     = "{{", DartExpression, "}}";
RawText           = ? all unicode characters ?;
```
