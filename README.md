# Hina
A sane programming language that compiles to Lua

Example: a calculator using the "parser-gen" Lua library.
```rust
let pg = require("lib.parser-gen.parser-gen");

let evaluate, eval_table, generate_binop;

let input = "(1 + 5) * 6";
let grammar = "

mul <- add (('*' / '/' / '%') add)*
add <- factor (('+'/'-') factor)*

NUMBER <- [0-9]+ ('.' [0-9]+)?
brackets <- '(' mul ')'

factor <- brackets / NUMBER

";

let parsed, _ = pg.parse(input, grammar);

let generate_binop = (f) => (ast) => {
    let val = evaluate(ast[1]);
    let i = 2;
    while ast[i], {
        let op = ast[i];
        let next = evaluate(ast[i + 1]);
        val = f(val, op, next);
        i = i + 2;
    };
    => val;
};

eval_table = {
    mul: generate_binop(
        (val, op, next) => 
            if op == "*", val * next 
            else if op == "/", val / next
            else val % next),
    add: generate_binop(
        (val, op, next) => 
            if op == "+", val + next else val - next),
    NUMBER: (ast) => tonumber(ast[1]),
    brackets: (ast) => evaluate(ast[2]),
    factor: (ast) => evaluate(ast[1])
};

evaluate = (ast) => eval_table[ast.rule](ast);

print(input .. " = " .. evaluate(parsed));
```
