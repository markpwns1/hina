# Hina
A sane programming language that compiles to Lua

### Features:
- Feature parity and interopability with Lua, with less verbose syntax
- The `require` function will no longer fail depending on where your working directory is, and now searches for files relative to the file it is called in.
- Advanced scope system with named scopes and the ability to return or break from multiple enclosing scopes
- The `continue` keyword like in C-like languages
- Try-catch blocks like in C-like languages
- The operators `not`, `and`, and `or` can now be overridden with the functions `__not`, `__and`, and `__or` in a table.

### In-Depth
Hina is an imperative, whitespace insensitive programming language, like Lua. Every statement *must* end with `;`.

#### Scopes
Scopes in Hina are themselves an expression, and can return a value.
```rust
let x = {
    let a = 4;
    let b = 5;
    => a + b; // => is equivalent to a return statement in other languages
};
print(x); // prints 9

// prints nothing because nothing was returned
print({
    let a, b, c = 1, 2, 3;
});
```
A scope cannot be empty. Otherwise, that would make it ambiguous between `{ }` and `{ }`--an empty table and an empty scope.

Scopes can have names, and return statements can choose to return to any scope, as long as it doesn't cross function boundaries. Scope names can start with numbers, and they can be alphanumeric and contain underscores.
```rust
let x = <1> {
    let y = <2> {
        <1> => 5; // Returns 5 for <1> AND ANY OTHER SCOPE IN BETWEEN, INCLUDING <2>
    };
};
print(x); // prints 5

// The following code prints 6 twice
// Scopes that are not named, are named <1>, <2>, and so on by default
print({
    print({
        <1> => 6;
    });
});
```

To return different things to different scopes, there exists a `return` keyword.
```rust
// The following code prints B then A
print({
    print({
        return [
            <1> => "A",
            <2> => "B"
        ];
    });
});
```

`break <x>;` is simply a shortcut for `<x> => nil;`, and likewise, the scope's name is optional. If a scope is not specified, it will do so with the current scope.

#### Control Flow
Hopefully the following code is self-explanatory
```rust
// Commas are optional
let x = if condition, 5 else if other_condition, 6 else 7;
```
As you can see, any expression can take the place of `5`, `6`, and `7`, including scopes.
```rust
// Commas are optional
if condition, something() else something_else();
```

Loops, however, are not expressions and so the following is **invalid**:
```rust
let y = rand_num_from_0_to_10();
let x = while y < 5, {
    y = rand_num_from_0_to_10();
};
```
So loops must be statements. See the following examples:
```rust
let i = 0;
while i < 10, { // Comma is optional
    print(i);
    i = i + 1;
};

let i = 0;
while i < 10 {
    if i == 4 {
        i = i + 1;
        continue <1>; // If the <1> is excluded, it will default to the closest loop
    };
    print(i);
    i = i + 1;
};

let i = 0;
while true {
    if i >= 5, break <1>;
    print(i);
    i = i + 1;
}
```
There are also `for-in` loops and `from` loops, they work the same way with `break` and `continue`. The commas are optional too, like with `if` statements and `while` loops.
```rust
let x = [ 1, 2, 3 ];
for i, v in ipairs(x), print(v);

// by and with are optional
from 1 -> 10 by 1 with i, print(i);
```

#### Arrays
An array can be declared like the following:
```rust
let a = [ 1, 2, 3 ];
```
This is just syntactic sugar for a Lua table containing `1, 2, 3`, and as such Lua's `table` library can be used to manipulate them. Arrays and tables are 1-indexed like in Lua.

#### Tables
A table can be declared like this:
```rust
let vec = {
    x: 1,
    y: 2 + 3
};
```
They are equivalent to Lua tables.

#### Operators
Some operators are changed from Lua. 
- `and` -> `&&`
- `or` -> `||`
- `not` -> `!`

All three of these can be overridden with `__not`, `__or`, `__and` inside a table, like other operators can.

#### Classes
Hina does not provide any syntactic sugar for classes. It does, however, export the variable `object` from the "Classic" library, which provides a simple abstraction over the metatable stuff that Lua requires in order to emulate classes. See the following file, `vec.hina`:
```rust
let vec = object:extend();

vec.new = (x, y) :=> {
    self.x, self.y = x, y;
};

vec.magnitude = () :=> math.sqrt(self.x ^ 2 + self.y ^ 2);

vec.__tostring = () :=> "(" .. self.x .. ", " .. self.y .. ")";

=> vec;
```
`vec` can then be used from other files like this:
```rust
let vec = require("vec");
let v = vec(1, 2);
print(v); // prints (1, 2)
```

#### Try-else-with Block
This is Hina's version of a try-catch block in C-like languages. It is both a statement and an expression.
```rust
let x = try y() else 5; // Will be 5 if y is not a function

// Will print the error if y is not a function
print(try y() else with err, err);

// Standard usage like in other languages
try {
    A();
} else with err {
    B(err);
};
```

### Example 
A calculator using the "parser-gen" Lua library.
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
