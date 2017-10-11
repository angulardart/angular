#Template Grammar

###Todos
* Can you interpolate comments?
* What is the best way to handle the additional constraints on expressions?
* What are we forgetting?


```dart
Node           = VoidTag | OpenTag {Node} CloseTag | Comment;
OpenTag        = "<" TagName WhiteSpace {WhiteSpace} {Attribute WhiteSpace {WhiteSpace}} ">";
VoidTag        = "<" TagName WhiteSpace {WhiteSpace} {Attribute WhiteSpace {WhiteSpace}} "/>";
CloseTag       = "</" TagName {WhiteSpace} ">";
Comment        = "<!--" {RawText} "-->";

Attribute      = Normal | Structural | Input | Event | Banana | Binding;
Normal         = AttributeName | AttributeName "=" Text;
Structural     = "*" AttributeName "=" (DartExpression | StructureSugar);
Input          = "[" AttributeName ["." AttributeName] "]=" DartExpression;
Event          = "(" AttributeName  ["." AttributeName] ")=" DartExpression;
Banana         = "[(" AttributeName ")]=" DartExpression;
Binding        = "#" AttributeName;
Text           = { RawText | Interpolation };
Interpolation  = "{{" DartExpression  ["|" DartIdentifier] "}}";

RawText        = ? valid unicode ?
DartIdentifier = Letter { Letter | Digit };
DartExpression = ? valid dart expression ?;
StructureSugar = ? valid sugar ?;
NSymbolUnicode = ? unicode - symbols ?

TagName        = LowerLetter {LowerLetter | Digit | "-"};
WhiteSpace     = " " | "\t" | "\n" | "\r" | "\f";
AttributeName  = NSymbolUnicode { NSymbolUnicode | "_" | "-"};
Letter         = "a" | "b" | ... | "Z";
Digit          = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" |"9";
```
