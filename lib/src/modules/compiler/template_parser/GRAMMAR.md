#Template Grammar

```
Node              = VoidTag | OpenTag [Node]* CloseTag | Comment
OpenTag           = "<" TagName WhiteSpace+ [Attribute WhiteSpace+]* ">"
VoidTag           = "<" TagName WhiteSpace+ [Attribute WhiteSpace+]* "/>"
CloseTag          = "</" TagName WhiteSpace* ">"
Comment           = "<!--" [RawText]+  "-->"

Attribute         = Normal | Structural | Input | Event | Banana | Binding
Normal            = AttributeName | AttributeName "=" '"' Text+ '"'
Structural        = "*" AttributeName "=" (DartExpression | StructuralExpression)
Input             = "[" AttributeName ["." AttributeName] "]=" DartExpression
Event             = "(" AttributeName  ["." AttributeName] ")=" DartExpression
Banana            = "[(" AttributeName ")]=" DartExpression
Binding           = "#" AttributeName
Text              = (RawText | Interpolation)*
Interpolation     = "{{" DartExpression ["|" DatIdentifier] "}}"

TagName           = Letter [(Digit | Letter)+] [ "-" (Digit | Letter)+ ]*
RawText           = ? all unicode characters ?
DartIdentifier    = ? valid dart identifier ?
WhiteSpace        = ? all whitespace characters ?
AttributeName     = [^"`'//=\t\n\r \(\)\[\]\*\.#]+
Letter            = [a-zA-Z]
Digit             = [0-9]
```
