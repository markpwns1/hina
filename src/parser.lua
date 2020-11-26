local pg = require("lib.parser-gen.parser-gen")

local error_labels = {
    missingCommaArray = "Missing comma to separate array values",
    missingRightHandVarDec = "Missing one or more values to assign",
    missingTableComma = "Missing comma to separate table values",
    missingCondition = "Missing a boolean condition",
    missingBody = "Missing body",
    missingIdentifier = "Missing an identifier (a name)",
    missingCommaGeneric = "Missing comma",
    missingDecList = "Missing one or more variable names",
    missingTupleVal = "Missing one or more values",
    missingExpr = "Missing expression",
    missingReturns = "Missing one or more values to return",
    missingNo = "Missing numeric value",
    missingThinArrow = "Missing '->'",
    missingLeftAssigments = "Missing one or more left-hand values to assign to",
    missingOpenSquare = "Missing '['",
    missingCloseSquare = "Missing ']'",
    missingReturn = "Missing one or more return statements",
    missingEquals = "Missing '='",
    missingOpenBracket = "Missing '('",
    missingCloseBracket = "Missing ')'",
    missingOpenCurly = "Missing '{'",
    missingCloseCurly = "Missing '}'",
    missingFnArrow = "Missing '=>' to indicate function",
    missingRetArrow = "Missing '=>' to indicate a return",
    missingOperator = "Missing operator",
    missingQuote = "Missing closing quote",
    missingLT = "Missing '<'",
    missingGT = "Missing '>'",
    missingReturnKwd = "Missing keyword 'return'",
    missingColon = "Missing ':'",
    missingFrom = "Missing 'from'",
    missingBy = "Missing 'by",
    missingWith = "Missing 'with'",
    missingSemicolon = "Missing ';'"
};

pg.setlabels(error_labels);

local grammar = pg.compile([[
    program <- (stmt ';'^missingSemicolon)+
    stmt <- (for_in_loop / for_loop / continue_stmt / break_stmt / while_loop / assignment / multi_ret / var_dec / ret / expr)

    for_in_loop <- 'for' ident_list 'in' expr comma stmt
    for_loop <- 'from' expr '->' expr ('by' expr)? ('with' IDENTIFIER)? comma stmt
    continue_stmt <- 'continue' block_name?
    break_stmt <- 'break' block_name?
    while_loop <- 'while' expr comma stmt
    tuple <- '(' expr (',' expr)+ ')'
    ret <- (block_name)? '=>' ((expr / tuple / '.')?)
    multi_ret <- 'return' '[' ret (',' ret)* ']'
    assignment <- assign_list '=' expr_list^missingRightHandVarDec

    dec_list <- IDENTIFIER (',' IDENTIFIER)*
    var_dec <- 'let' dec_list ('=' expr_list^missingRightHandVarDec)?

    fragment expr <- concat

    CONCATOP <- '..'
    concat <- boolean_logic (CONCATOP boolean_logic)*

    BOOLOP <- '||' / '&&'
    boolean_logic <- equality (BOOLOP equality)*

    EQOP <- '==' / '!='
    equality <- not_op (EQOP not_op)*

    not_op <- '!'* numeric_comparison

    NUMCOMPOP <- '<=' / '>=' / '<' / '>'
    numeric_comparison <- add (NUMCOMPOP add)*

    ADDOP <- [+-]
    add <- mul (ADDOP mul)*
    MULOP <- [*/%]
    mul <- neg (MULOP neg)*
    neg <- '-'* exp
    EXPOP <- '^'
    exp <- bitshift (EXPOP bitshift)*

    BITSHIFTOP <- '<<' / '>>'
    bitshift <- bin_op (BITSHIFTOP bin_op)*

    BITOP <- '&' / '|' / '~'
    bin_op <- bin_not (BITOP bin_not)*

    bin_not <- '~'* index_call

    traverse <- '.' IDENTIFIER
    index <- '[' expr? ']'
    call <- '(' expr_list? ')'
    selfcall <- ':' IDENTIFIER call
    index_call <- factor (index / call / traverse / selfcall)*

    KEYWORDS <- 'break' / 'continue' / 'from' / 'by' / 'with' / 'while' / 'let' / 'return' / 'fn' / 'if' / 'else'
    IDREST <- [a-zA-Z_0-9]
    RESERVED <- KEYWORDS !IDREST
    IDENTIFIER <- !RESERVED [a-zA-Z_] [a-zA-Z0-9_]*

    NUMBER <- [0-9]+ ('.' [0-9]+)?
    boolean <- 'true' / 'false'
    brackets <- '(' expr ')'
    STRING <- '"' { [^"\]* } '"'
    array <- '[' field_list? ']'
    table <- '{' table_values? '}'
    func <- '(' arg_list? ')' ':'? '=>' ((expr / tuple / '.')?)
    null <- 'nil'

    block_name <- '<' IDREST '>'
    block <- block_name? '{' program '}'
    fragment comma <- ','?
    if_expr <- 'if' expr comma (expr / stmt) ('else' (expr / stmt))?

    factor <- if_expr / func / brackets / NUMBER / boolean / null / IDENTIFIER / STRING / array / block / table

    ident_list <- IDENTIFIER (',' IDENTIFIER)*
    assign_list <- index_call (',' index_call)*
    arg_list <- IDENTIFIER (',' IDENTIFIER !'...')* (',' IDENTIFIER '...')?
    expr_list <- expr (',' expr)*
    field_list <- expr (',' expr)* ','?
    table_val <- IDENTIFIER ':' expr
    table_values <- table_val (',' table_val)* ','?

    fragment COMMENT <- '//' (. !%nl)* .
    fragment MULTILINE_COMMENT <- '/*' (. !'*/')* . '*/'
    HELPER <- ';' / %nl / %s / KEYWORDS / !.
    SYNC <- (!HELPER .)*
    SKIP <- %s / %nl / COMMENT / MULTILINE_COMMENT
]]);

local function string_trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local error_count = 0
local error_text = ""
local function print_error(desc, line, col, sfail, trec)
    error_count = error_count + 1
    
    error_text = error_text 
        .. error_count .. ". " 
        .. desc .. " at '" .. string_trim(sfail) 
        .. "' -- ln " .. line .. " col " .. col .. "\n"
end

local function parse(input, silent)
    local ast, errors = pg.parse(input, grammar, ternary(silent, nil, print_error))
    return {
        ast = ast,
        errors = errors,
        error_text = error_text
    }
end

return parse