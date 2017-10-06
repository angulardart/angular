## Priority issues

These are blocking the package from replacing the current parser

- [x] Parse structural directives
- [x] Lex interpolation
- [x] Parse interpolation
- [x] Parse embedded templates
- [x] Parse embedded content
- [x] Support implicitly void elements (`<input>`)
- [x] Support banana syntax (event and property setter)
- [x] Lex expressions
- [x] Parse expressions
- [x] Support the `*ngFor` style multiple-expressions/properties
- [x] Add AST visitor, and `accept` methods to AST classes
- [x] Support explicitly void elements (`<foo />`)

Potentially not support

- [ ] Support interpolated property setters
- [x] Lex expressions
- [x] Parse expressions
- [ ] Add AST visitor, and `accept` methods to AST classes

## Secondary issues

These are needed to add useful features on top of current support

- [ ] Support explicitly void elements (`<foo />`)
- [ ] Add AST rewrite support (for refactoring tools)
    - [ ] Be able to remove an element
    - [ ] Be able to remove a decorator
    - [ ] Be able to add an element
    - [ ] Be able to add a decorator
    - [ ] Be able to rename an element tag
    - [ ] Be able to rename a decorator name
    - [ ] Be able to change an expression
- [ ] Add resolver and schema support
- [ ] Add friendly error class with auto-fix support
- [x] Add "sugared" version of the AST tree (for tooling)
    - [x] BananaSugarAst
    - [x] StructuralSugarAst
