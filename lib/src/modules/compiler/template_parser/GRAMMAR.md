```dart
Tag = TagSelfClosing | TagOpen, [RawText | Tag+ | Comment], TagClose ;

TagOpen = "<", TagName, Whitespace+, [Attribute, Whitespace]*, ">" ;

TagSelfClosing = "<", TagName, Whitespace+, [Attribute, [Whitespace]+]* , "/>" ;

TagClose = "</", TagName, Whitespace*, ">" ;

Comment = "<!--", [Text]+ , "-->"

Attribute = Normal | Structural | Input | Output | Banana | Binding ;

Normal = AttributeName | AttributeName, "=", AttributeValue ;

AttributeValue = '"', RawText , '"' ;

Structural = "*", AttributeName, "=", '"', (DartExpression | NgForExpression), '"' ;

Input = "[", AttributeName, "]", "=", '"', DartExpression ;

Output= "(", AttributeName, ")", "=", '"', DartExpression ;

Combined = "[(", AttributeName, ")", "]", "=", '"', DartExpression ;
```
