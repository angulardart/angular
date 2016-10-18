#Template Grammar

###Todos
* Can you interpolate comments?
* Can you have multiple pipes?
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

RawText        = { Letter | Digit };
DartIdentifier = Letter { Letter | Digit };
DartExpression = ? valid dart expression ?
StructureSugar = { Letter | Digit };

TagName        = LowerLetter {LowerLetter | Digit | "-"};
WhiteSpace     = " " | "\t" | "\n" | "\r" | "\f";
AttributeName  = Letter {Letter | Digit | "_" | "-"};
Letter         = LowerLetter | UpperLetter;
LowerLetter    = "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" |
                 "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" |
                 "u" | "v" | "w" | "x" | "y" | "z" ;
UpperLetter    = "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" |
                 "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" |
                 "U" | "V" | "W" | "X" | "Y" | "Z" ;
Digit          = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" |"9";
```
