#Template Grammar

```
WhiteSpace        = ? all whitespace characters ?
Letter            = [a-zA-Z]
Digit             = [0-9]
Fragment          = (Digit | Letter)+
TagName           = Letter [Fragment] [ "-" Fragment ]*
Node              = VoidTag | OpenTag [Node]* CloseTag | Comment
OpenTag           = "<" TagName WhiteSpace+ [Attribute WhiteSpace+]* ">"
VoidTag           = "<" TagName WhiteSpace+ [Attribute WhiteSpace+]* "/>"
CloseTag          = "</" TagName WhiteSpace* ">"
Comment           = "<!--" [RawText]+  "-->"
AttributeName     = [^"`'//=\t\n\r \(\)\[\]\*\.#]+
AttributeValue    = '"' Text+ '"'
Attribute         = Normal | Structural | Input | Event | Banana | Binding
Normal            = AttributeName | AttributeName "=" AttributeValue
Structural        = "*" AttributeName "=" (DartExpression | StructuralExpression)
Input             = "[" AttributeName ["." AttributeName] "]=" DartExpression
Event             = "(" AttributeName  ["." AttributeName] ")=" DartExpression
Banana            = "[(" AttributeName ")]=" DartExpression
Binding           = "#" AttributeName
Text              = (RawText | Interpolation)*
Interpolation     = "{{" DartExpression ["|" DatIdentifier] "}}"
RawText           = ? all unicode characters ?
DartIdentifier    = ? valid dart identifier ?
```
