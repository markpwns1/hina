-- local oldRequire = require
-- require = function (p)
--     oldRequire("src." .. p)
-- end
-- -- local x = require("lpeglabel")
inspect = require("lib.inspect")

local HINA_VERSION = "pre-0.1.1"

local pg = require("lib.parser-gen.parser-gen")
local Stack = require("stack")
local tablex = require("lib.tablex")
local stringx = require("lib.stringx")
local set = require("lib.set")
-- pg.usenodes(true)
local indent = 0
local depth = 0
local scopes = Stack()
local return_commands = { }

local function newline(txt)
    txt = txt .. "\n"
    for i = 1, indent do
        txt = txt .. "  "
    end
    return txt
end

local function new_indent(txt)
    indent = indent + 1
    txt = newline(txt)
    return txt
end

local function end_indent(txt)
    indent = indent - 1
    txt = newline(txt)
    return txt
end

local function get_scope_nest()
    return scopes:len()
end

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
}

pg.setlabels(error_labels)

local function string_trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local errs = 0
local errtext = ""
local function printerror(desc,line,col,sfail,trec)
    errs = errs+1
    
	errtext = errtext .. (errs..". "..desc.." at '"..string_trim(sfail).."' -- ln "..line.." col "..col .. "\n")
end

--if_stmt <- 'if' expr comma expr ('else' expr)?
-- local grammar = pg.compile([[
--     program <- stmt+
--     stmt <- (for_loop / continue_stmt / break_stmt / while_loop / assignment / multi_ret / var_dec / ret / expr) ';'?

--     for_loop <- 'from' expr^missingExpr '->'^missingThinArrow expr^missingExpr ('by'^missingBy expr^missingExpr)? ('with'^missingWith IDENTIFIER^missingIdentifier)? comma stmt
--     continue_stmt <- 'continue' block_name?
--     break_stmt <- 'break' block_name?
--     while_loop <- 'while' expr^missingCondition comma stmt^missingBody
--     tuple <- '('^missingOpenBracket expr (','^missingCommaGeneric expr)+ ')'^missingCloseBracket
--     ret <- (block_name)? '=>' ((expr / tuple / '.')?)
--     multi_ret <- 'return'^missingReturnKwd '['^missingOpenSquare ret (','^missingCommaGeneric ret)* ']'^missingCloseSquare
--     assignment <- assign_list '='^missingEquals expr_list

--     dec_list <- IDENTIFIER (',' IDENTIFIER)*
--     var_dec <- 'let' dec_list ('='^missingEquals expr_list)?

--     fragment expr <- concat

--     CONCATOP <- '..'
--     concat <- boolean_logic (CONCATOP boolean_logic)*

--     BOOLOP <- '||' / '&&'
--     boolean_logic <- equality (BOOLOP equality)*

--     EQOP <- '==' / '!='
--     equality <- not_op (EQOP not_op)*

--     not_op <- '!'* numeric_comparison

--     NUMCOMPOP <- '<' / '<=' / '>' / '>='
--     numeric_comparison <- add (NUMCOMPOP add)*

--     ADDOP <- [+-]
--     add <- mul (ADDOP mul)*
--     MULOP <- [*/%]
--     mul <- neg (MULOP neg)*
--     neg <- '-'* bitshift

--     BITSHIFTOP <- '<<' / '>>'
--     bitshift <- bin_op (BITSHIFTOP bin_op)*

--     BITOP <- '&' / '|' / '~'
--     bin_op <- bin_not (BITOP bin_not)*

--     bin_not <- '~'* index_call

--     traverse <- '.' IDENTIFIER^missingIdentifier
--     index <- '[' expr? ']'^missingCloseSquare
--     call <- '(' expr_list? ')'^missingCloseBracket
--     index_call <- factor (index / call / traverse)*

--     KEYWORDS <- 'from' / 'by' / 'with' / 'while' / 'let' / 'return' / 'fn' / 'if' / 'else'
--     IDREST <- [a-zA-Z_0-9]
--     RESERVED <- KEYWORDS !IDREST
--     IDENTIFIER <- !RESERVED [a-zA-Z_] [a-zA-Z0-9_]*

--     NUMBER <- [0-9]+ ('.' [0-9]+)?
--     boolean <- 'true' / 'false'
--     brackets <- '(' expr ')'^missingCloseBracket
--     STRING <- '"' { [^"\]* } '"'^missingQuote
--     array <- '[' field_list? ']'^missingCloseSquare
--     table <- '<{' table_values? '}>'^missingCloseCurly
--     func <- '(' arg_list? ')'^missingCloseBracket '=>'^missingFnArrow ((expr / tuple / '.')?)^missingExpr
--     null <- 'nil'

--     block_name <- '<'^missingLT IDREST '>'^missingGT
--     block <- block_name '{' program '}'^missingCloseCurly
--     fragment comma <- ','?
--     if_expr <- 'if' expr^missingCondition comma expr^missingBody ('else' expr^missingBody)?

--     factor <- if_expr / func / brackets / NUMBER / boolean / null / IDENTIFIER / STRING / array / block / table

--     assign_list <- index_call (',' index_call)*
--     arg_list <- IDENTIFIER (',' IDENTIFIER !'...')* (',' IDENTIFIER '...')?
--     expr_list <- expr (',' expr)*
--     field_list <- expr (',' expr)* ','?
--     table_val <- IDENTIFIER^missingIdentifier ':'^missingColon expr^missingExpr
--     table_values <- table_val (',' table_val)* ','?

--     HELPER <- ';' / %nl / %s / KEYWORDS / !.
-- 	SYNC <- (!HELPER .)*
-- ]])

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
    neg <- '-'* bitshift

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
]])

--[[
    let add = (x, y) => 5
]]

-- STRCHAR <- ('\\' .) / (. & (!'"'))
-- local res, _ = pg.parse([[

--     !(-x % -2 + (~~1 | 0 << 2) == 2) && a || b

-- ]], grammar)


function show(x)
    print(inspect(x))
end

-- local file = io.open(arg[1], "r")
-- local code = file:read("*all")
-- file:close()

-- local res, errors
-- if not pcall(function() 
--     res, errors = pg.parse(code, grammar, printerror) 
-- end) then
--     error("Unspecified syntax error")
-- end
-- res, errors = pg.parse(code, grammar, printerror) 


-- show(errors)

local output = ""
local function emit(x)
    output = output .. x
end

local evaluate
local function type_compatible(a, b)
    assert(a ~= nil, "Left type is null")
    assert(b ~= nil, "Right type is null")
    return a == "any" or b == "any" or a == b
end

local function assert_type(a, b)
    if not type_compatible(a, b) then
        error("Expected object of type " .. b .. " but got " .. a)
    end
end


local function ternary(cond, t, f)
    if cond then return t else return f end
end

local function table_contains(t, f)
    for k, v in pairs(t) do
        if f(k, v) then return true end
    end
    return false
end

local function contains_table(t)
    local i = 1
    while t[i] do
        if type(t[i]) == "table" then return true end
        i = i + 1
    end
    return false
end

local function generate_binop_advanced(l_type, r_type, out_type, f)
    return function(ast)
        local left = evaluate(ast[1])
        
        -- show(left)
        local last_type = left.h_type
        local text = left.text
        local i = 1
        if ast[i + 2] then
            assert_type(last_type, l_type)
        else
            return {
                text = text,
                h_type = left.h_type
            }    
        end
        i = 2
        while ast[i] do
            local op = ast[i][1]

            if not op then
                -- show(ast[i])
                error("No op??? " .. inspect(ast[i]))
            end

            local next_val = evaluate(ast[i + 1])
            if ast[i + 2] then
                assert_type(next_val.h_type, r_type)
            end

            -- print(next_val.h_type)
            last_type = ternary(next_val.h_type == "any" or last_type == "any", "any", out_type)

            text = f(text, op, next_val.text)
            i = i + 2
        end
        return {
            text = text,
            h_type = out_type
        }
    end
end

local function _generate_binop_noreplace(left, op, right)
    return "(" .. left .. " " .. op .. " " .. right .. ")" 
end

local function generate_binop(l_type, r_type, out_type, op_replace_table)
    local f
    if op_replace_table then
        f = function(left, op, right)
            return "(" .. left .. " " .. (op_replace_table[op] or op) .. " " .. right .. ")" 
        end
    else
        f = _generate_binop_noreplace
    end
    return generate_binop_advanced(l_type, r_type, out_type, f)
end

local function generate_unboxer(i)
    return function(ast)
        local eva = evaluate(ast[i])
        return {
            text = eva.text,
            h_type = eva.h_type
        }
    end
end

local function generate_factor(type, i)
    if not i then i = 1 end
    return function (ast)
        return {
            text = ast[i],
            h_type = type
        }
    end
end

local function parse_field_list(list, f, start)
    if not start then start = 1 end
    local i = start
    while list[i] do
        f(list[i])
        i = i + 2
    end
end

local function get_parent_block()
    local parent_block
    local i = 0
    while i < scopes:len() do
        local s = scopes:peek(i)
        if s.type == "block" then 
            parent_block = s.name
            break
        end
        i = i + 1
    end
    return parent_block
end

local function generate_unary_op(symbol, in_type, out_type, f)
    return function(ast)
        local nots = 0
        while ast[nots + 1] == symbol do
            nots = nots + 1
        end
        local eva = evaluate(ast[nots + 1])
        local text = eva.text
        local type = eva.h_type
        -- print(eva.h_type)
        if nots > 0 then
            assert_type(eva.h_type, in_type)
        else 
            return {
                text = text,
                h_type = type
            }
        end

        type = ternary(type == "any", "any", out_type)
        for i = 1, nots, 1 do
            text = f(text)
        end
        return {
            text = text,
            h_type = type
        }
    end
end

local function check_return(text, block_name)
    if tablex.index_of(return_commands, block_name) ~= nil then
        -- show(return_commands)
        tablex.remove_value(return_commands, block_name)
        -- show(return_commands)
        text = newline(text)
        text = text .. "if __h_return_value_" .. block_name .. " then"
        text = new_indent(text)
        text = text .. "local __h_temp = __h_return_value_" .. block_name
        text = newline(text)
        text = text .. "__h_return_value_" .. block_name .. " = nil"
        text = newline(text)
        text = text .. "return __h_unpack(__h_temp)"
        text = end_indent(text)
        text = text .. "end"
    end
    return text
end

local unbox_ast = generate_unboxer(1)

local ast_traverse = {
    program = function(ast)
        local text = ""
        local pc = 1
        while ast[pc] do
            if ast[pc] ~= ";" then
                text = text .. evaluate(ast[pc]).text .. ";"
                text = newline(text)
            end
            pc = pc + 1
        end
        return {
            text = text,
            h_type = "void"
        }
    end,
    comment = function (ast)
        return { text = "", h_type = "void" }
    end,
    stmt = function(ast)
        -- print("BEHOLD")
        -- show(ast)
        -- if ast[1].rule == "expr" and ast[1][1] and ast[1][1] then
        --     error("Expression used as statement")  
        -- end
        return unbox_ast(ast)
    end,
    assignment = function (ast)
        local text = ""
        parse_field_list(ast[1], function (x)
            local eva = evaluate(x)
            if eva.ends_with_call then
                error("Cannot assign directly to the result of a function")
            end
            text = text .. eva.text .. ", "
        end)
        text = text:sub(1, text:len() - 2) 

        text = text .. " = "

        parse_field_list(ast[3], function (x)
            text = text .. evaluate(x).text .. ", "
        end)
        text = text:sub(1, text:len() - 2) 

        return {
            text = text,
            h_type = "void"
        }
    end,
    tuple = function (ast)
        -- show(ast)
        local text = ""
        local i = 2
        while ast[i] do 
            text = text .. evaluate(ast[i]).text .. ternary(ast[i + 2], ", ", "")
            i = i + 2
        end
        return {
            text = text .. ""
        }
    end,
    multi_ret = function (ast)
        local text = ""
        local i = 3

        -- TODO: make sure you cant include scopes twice
        local used_scopes = { }

        local function l()
            local r = ast[i]
            local offset = 0
            local scope_name
            -- show(r)
            if r[1].rule == "block_name" then
                scope_name = r[1][2][1]
                offset = 1
            else
                scope_name = scopes:peek().name
            end

            if tablex.index_of(used_scopes, scope_name) ~= nil then
                -- show(used_scopes)
                error("The scope <" .. scope_name .. "> is included multiple times in a multi-return")
            end

            table.insert(used_scopes, scope_name)

            if not table_contains(scopes.stack, function(k, v)
                return v.name and v.name == scope_name
            end) then
                error("A scope with name '" .. scope_name .. "' does not exist")
            end

            local v = r[2 + offset]
            local val = { text = "nil" }
            if v and v ~= "." then val = evaluate(v) end
            table.insert(return_commands, scope_name)
            text = text .. "__h_return_value_" .. scope_name .. " = __h_pack(" .. val.text .. ")"
            text = newline(text)
        end

        l()
        i = i + 2
        while ast[i] do
            l()
            i = i + 2
        end

        text = text .. "do return __h_unpack(__h_return_value_" .. scopes:peek().name .. ") end"
        return {
            text = text,
            h_type = "void"
        }
    end,
    continue_stmt = function(ast)
        if ast[2] and ast[2].rule == "block_name" then
            
            local block_name = ast[2][2][1]
            local text = ""
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot return past a function scope")
                end

                -- print(s.type)
                
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    text = text .. "__h_return_value_" .. s.name .. " = __h_pack(nil)"
                    text = newline(text)
                    
                    if s.name == block_name then 
                        local parent = scopes:peek(i + 1)
                        if parent and parent.type == "loop" then
                            -- text = text .. "__h_loop_" .. parent.id .. " = false"
                            -- text = newline(text)
                        else 
                            error("Can only continue a loop")
                        end
                        break 
                    end
                elseif s.type == "loop" then 
                    text = text .. "__h_loop_" .. s.id .. " = false"
                    text = newline(text)
                end
                i = i + 1
            end

            text = text .. "do return __h_unpack(__h_return_value_" .. block_name .. ") end"
            return {
                text = text,
                h_type = "void"
            }
        else
            local text = ""
            local parent = scopes:peek(1)
            if parent and parent.type == "loop" then
                text = text .. "__h_loop_" .. parent.id .. " = false"
                text = newline(text)
            end
            return {
                text = text .. "do return end",
                h_type = "void"
            }
        end
    end,
    break_stmt = function(ast)
        if ast[2] and ast[2].rule == "block_name" then
            
            local block_name = ast[2][2][1]
            local text = ""
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot break past a function scope")
                end

                -- print(s.type)
                
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    text = text .. "__h_return_value_" .. s.name .. " = __h_pack(nil)"
                    text = newline(text)
                    
                    if s.name == block_name then 
                        local parent = scopes:peek(i + 1)
                        if parent and parent.type == "loop" then
                            text = text .. "__h_loop_" .. parent.id .. " = false"
                            text = newline(text)
                        end
                        break 
                    end
                elseif s.type == "loop" then 
                    text = text .. "__h_loop_" .. s.id .. " = false"
                    text = newline(text)
                end
                i = i + 1
            end

            text = text .. "do return __h_unpack(__h_return_value_" .. block_name .. ") end"
            return {
                text = text,
                h_type = "void"
            }
        else
            local text = ""
            local parent = scopes:peek(1)
            local grandparent = scopes:peek(2)
            if parent and parent.type == "loop" then
                text = text .. "__h_loop_" .. parent.id .. " = false"
                text = newline(text)
            elseif  grandparent and grandparent.type == "loop" then
                text = text .. "__h_loop_" .. grandparent.id .. " = false"
                text = newline(text)
            end
            return {
                text = text .. "do return end",
                h_type = "void"
            }
        end
    end,
    ret = function (ast)
        if ast[1].rule == "block_name" then
            
            local block_name = ast[1][2][1]
            local val = ternary(ast[3] == ".", "nil", nil)
            -- show(ast[3]);
            val = val or evaluate(ast[3])
            local text = ""
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot return past a function scope")
                end
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    text = text .. "__h_return_value_" .. s.name .. " = __h_pack(" .. ((val and val.text) or "nil") .. ")"
                    text = newline(text)

                    if s.name == block_name then 
                        local parent = scopes:peek(i + 1)
                        if parent and parent.type == "loop" then
                            text = text .. "__h_loop_" .. parent.id .. " = false"
                            text = newline(text)
                        end
                        break 
                    end
                elseif s.type == "loop" then 
                    text = text .. "__h_loop_" .. s.id .. " = false"
                    text = newline(text)
                end
                i = i + 1
            end

            text = text .. "do return __h_unpack(__h_return_value_" .. block_name .. ") end"
            return {
                text = text,
                h_type = "void"
            }
        else
            local text = ""
            local parent = scopes:peek(1)
            local grandparent = scopes:peek(2)
            if parent and parent.type == "loop" then
                text = text .. "__h_loop_" .. parent.id .. " = false"
                text = newline(text)
            elseif  grandparent and grandparent.type == "loop" then
                text = text .. "__h_loop_" .. grandparent.id .. " = false"
                text = newline(text)
            end
            
            local val = ternary(ast[2] == ".", "nil", nil)
            if ast[2] then
                val = val or evaluate(ast[2])
            end
            return {
                text = text .. "do return " .. ((val and val.text) or "nil") .. " end",
                h_type = "void"
            }
        end
    end,
    var_dec = function (ast)
        -- show(ast)
        local names = ast[2]
        local text = "local "
        local i = 1
        while names[i] do
            text = text .. names[i][1] .. ternary(names[i + 2], ", ", "")
            i = i + 2
        end
        if ast[3] then
            text = text .. " = "
            parse_field_list(ast[4], function (x)
                text = text .. evaluate(x).text .. ", "
            end)
            text = text:sub(1, text:len() - 2) 
        end
        return {
            text = text,
            h_type = "void"
        }
    end,
    expr = unbox_ast,
    concat = generate_binop("any", "any", "string"),
    boolean_logic = generate_binop_advanced("bool", "bool", "bool", function(left, op, right)
        local f
        if op == "&&" then
            f = "__h_and"
        elseif op == "||" then
            f = "__h_or"
        else 
            error("not and or or????")
        end
        return f .. "(" .. left .. ", " .. right .. ")"
    end),
    equality = generate_binop("any", "any", "bool", { ["!="] = "~=" }),
    not_op = generate_unary_op("!", "bool", "bool", function(text)
        return "__h_not(" .. text .. ")"
    end),
    numeric_comparison = generate_binop("num", "num", "bool"),
    add = generate_binop("num", "num", "num"),
    mul = generate_binop("num", "num", "num"),
    neg = generate_unary_op("-", "num", "num", function(text)
        return "-" .. text
    end),
    bin_not = generate_unary_op("~", "num", "num", function(text)
        return "~" .. text
    end),
    bitshift = generate_binop("num", "num", "num"),
    bin_op = generate_binop("num", "num", "num"),
    index_call = function (ast)
        local left = evaluate(ast[1])
        local text = left.text
        if not ast[2] then
            return {
                text = text,
                h_type = left.h_type
            }
        end
        local i = 2
        local ends_with_call = false
        while ast[i] do
            if ast[i].rule == "index" then
                local index = evaluate(ast[i][2])
                -- show(ast)
                text = text .. "[" .. index.text .. "]"
                ends_with_call = false
            elseif ast[i].rule == "call" then 
                -- show(ast[2])
                text = text .. "("
                if ast[i][2] ~= ")" then 
                    parse_field_list(ast[i][2], function (x)
                        -- show(x)
                        text = text .. evaluate(x).text .. ", "
                    end) 
                    text = text:sub(1, text:len() - 2)   
                end
                text = text .. ")"
                ends_with_call = true
            elseif ast[i].rule == "traverse" then
                text = text .. "." .. ast[i][2][1]
                ends_with_call = false
            elseif ast[i].rule == "selfcall" then
                text = text .. ":" .. ast[i][2][1] .. "("
                -- show(ast[i])
                if ast[i][3][2] ~= ")" then 
                    parse_field_list(ast[i][3][2], function (x)
                        -- show(x)
                        text = text .. evaluate(x).text .. ", "
                    end) 
                    text = text:sub(1, text:len() - 2)   
                end
                text = text .. ")"
                ends_with_call = true
            else
                error("wtf")
            end
            i = i + 1
        end
        -- show(ast[i])
        return {
            text = text,
            h_type = "any",
            ends_with_call = ends_with_call
        }
    end,
    factor = unbox_ast,
    brackets = generate_unboxer(2),
    number = generate_factor("num"),
    identifier = generate_factor("any"),
    boolean = generate_factor("bool"),
    string = function(ast)
        -- show(ast)
        return {
            text = "[[" .. ast[2] .. "]]",
            h_type = type
        }
    end,
    null = function(ast)
        return {
            text = "nil",
            h_type = "nil"
        }
    end,
    array = function (ast)
        local text = "{ "
        -- print("huh???")
        -- if ast[2] ~= "]" then
            parse_field_list(ast[2], function (x)
                text = text .. evaluate(x).text .. ", "
            end)
        -- end
        text = text .. "}"
        return {
            text = text,
            h_type = "array"
        }
    end,
    block = function (ast)
        local text = "(function()"
        text = new_indent(text)

        local pc = 1
        depth = depth + 1
        local block_annotation = "-- Depth: " .. depth
        local block_name = "" .. depth
        local statements 

        if ast[1] == "{" then
            -- block_annotation = "::__h_block_" .. depth .. ":: "
            statements = ast[2]
        else 
            block_name = ast[1][2][1]
            -- block_annotation = "::__h_block_" .. ast[1][2][1] .. ":: "
            statements = ast[3]
        end

        if table_contains(scopes.stack, function(k, v)
            return v.name and v.name == block_name
        end) then
            error("A scope with name '" .. block_name .. "' already exists")
        end

        scopes:push({
            type = "block",
            name = block_name,
            depth = depth
        })

        while statements[pc] do
            text = text .. evaluate(statements[pc]).text .. ";"

            text = check_return(text, block_name)

            if statements[pc + 1] then
                text = newline(text)
            end

            pc = pc + 2
        end

        scopes:pop()
        depth = depth - 1

        text = newline(text)
        text = text .. block_annotation
        text = end_indent(text)
        text = text .. "end)()"
        return {
            text = text,
            h_type = "any"
        }
    end,
    for_loop = function (ast)
        local from = evaluate(ast[2])
        assert_type(from.h_type, "num")

        local to = evaluate(ast[4])
        assert_type(to.h_type, "num")

        local offset = 0
        local by
        if ast[5] == "by" then
            by = evaluate(ast[6])
            assert_type(by.h_type, "num")
            offset = 2
        end

        local var_name
        if ast[5 + offset] == "with" then
            var_name = ast[6 + offset][1]
            offset = offset + 2
        end

        offset = offset + ternary(ast[5 + offset] == ",", 1, 0)
        local id = get_scope_nest() 

        scopes:push({
            type = "loop",
            id = id,
            depth = depth
        })

        local body = evaluate(ast[5 + offset])

        scopes:pop()

        local parent_block = get_parent_block()

        local text = "for " .. ternary(var_name, var_name, "_") .. " = " .. from.text 
            .. ", " .. to.text .. ternary(by, ", " .. by.text, "") .. " do"
        text = new_indent(text)
        text = text .. "if not __h_loop_" .. id .. " then break end"
        text = newline(text)
        text = text .. body.text
        text = newline(text)
        text = check_return(text, parent_block)
        text = end_indent(text)
        text = text .. "end"

        return {
            text = text,
            h_type = "void",
        }
    end,
    for_in_loop = function (ast)
        local text = ""
        local collection = evaluate(ast[4])
        
        local id = get_scope_nest() 
        scopes:push({
            type = "loop",
            id = id,
            depth = depth
        })

        local body = evaluate(ternary(ast[5] == ",", ast[6], ast[5]))

        scopes:pop()
        
        local parent_block = get_parent_block()

        text = text .. "local __h_loop_" .. id .. " = true"
        text = newline(text)
        text = text .. "for "

        parse_field_list(ast[2], function (x)
            text = text .. x[1] .. ", "
        end)

        text = text:sub(1, text:len() - 2) 
        
        text = text .. " in " .. collection.text .. " do"
        text = new_indent(text)
        text = text .. "if not __h_loop_" .. id .. " then break end"
        text = newline(text)
        text = text .. body.text
        text = newline(text)
        text = check_return(text, parent_block)
        text = end_indent(text)
        text = text .. "end"
        return {
            text = text,
            h_type = "void"
        }
    end,
    while_loop = function (ast)
        local cond = evaluate(ast[2])
        assert_type(cond.h_type, "bool")

        local offset = ternary(ast[3] == ",", 1, 0)
        local id = get_scope_nest() 

        scopes:push({
            type = "loop",
            id = id,
            depth = depth
        })

        local body = evaluate(ast[3 + offset])

        scopes:pop()

        local parent_block = get_parent_block()

        local text = "local __h_loop_" .. id .. " = true"
        text = newline(text)
        text = text .. "while __h_loop_" .. id .. " and (" .. cond.text .. ") do"
        text = new_indent(text)
        text = text .. body.text
        text = newline(text)
        text = check_return(text, parent_block)
        text = end_indent(text)
        text = text .. "end"

        return {
            text = text,
            h_type = "void",
        }
    end,
    if_expr = function (ast)
        local cond = evaluate(ast[2])
        local offset = ternary(ast[3] == ",", 1, 0)

        scopes:push({
            type = "if",
            depth = depth
        })

        local if_true = evaluate(ast[3 + offset])
        assert_type(cond.h_type, "bool")
        local text = "(function()"
        text = new_indent(text)
        text = text .. "if " .. cond.text .. " then"
        text = new_indent(text)
        if ast[3 + offset].rule == "expr" then
            text = text .. "return " .. if_true.text
        else 
            text = text .. if_true.text
        end
        text = end_indent(text)
        if ast[5 + offset] then
            local if_false = evaluate(ast[5 + offset])
            text = text .. "else"
            text = new_indent(text)
            if ast[5 + offset].rule == "expr" then
                text = text .. "return " .. if_false.text
            else 
                text = text .. if_false.text
            end
            text = end_indent(text)
        end

        scopes:pop()

        
        text = text .. "end"
        text = end_indent(text)
        text = text .. "end)()"
        text = newline(text)

        local parent_block = get_parent_block()
        text = check_return(text, parent_block)
        text = newline(text)
        -- text = text .. "if __h_return_value_" .. depth .. " then"
        -- text = new_indent(text)
        -- text = text .. "local __h_temp = __h_return_value_" .. depth
        -- text = newline(text)
        -- text = text .. "return __h_temp"
        -- text = end_indent(text)
        -- text = text .. "end"
        return {
            text = text,
            h_type = "any"
        }
    end,
    func = function (ast)
        local text = ""
        local args = ast[2]
        local offset = -1
        local vararg_name
        if args ~= ")" then
            local i = 1
            while args[i] do
                local arg = args[i]
                local name = arg[1]
                local is_vararg = args[i + 1] == "..."
                vararg_name = ternary(is_vararg, name, nil)
                -- show(arg)
                -- show()
                text = text .. ternary(is_vararg, "...", name .. ternary(args[i + 2], ", ", ""))
                i = i + 2
            end
            offset = 0
        end
        text = text .. ")"
        text = new_indent(text)
        if vararg_name then
            text = text .. "local " .. vararg_name .. " = { ... }"
            text = newline(text)
        end
        scopes:push({
            type = "func",
            depth = depth
        })

        -- show(ast)
        if ast[4 + offset] == ":" then
            offset = offset + 1 
            text = "function(self, " .. text
        else 
            text = "function(" .. text
        end
        -- show(5 + offset)
        local val = ast[5 + offset]
        if val == "." then
            text = text .. "return nil"
        else 
            -- print("spot: " .. (5 + offset))
            -- show(ast)
            if val == nil then
                error("Expected expression after '=>' in a function")
            end

            text = text .. "return " .. evaluate(val).text
        end
        scopes:pop()
        text = end_indent(text)
        text = text .. "end"
        return {
            text = text,
            h_type = "func"
        }
    end,
    table = function (ast)
        local text = "{ "
        local items = ast[2]
        local i = 1
        while items[i] do
            local item = items[i]
            -- show(item)
            local name = item[1][1]
            local val = item[3]
            -- show()
            text = text .. name .. " = " .. evaluate(val).text .. ", "
            i = i + 2
        end
        text = text .. "}"
        return {
            text = text,
            h_type = "any"
        }
    end,
}

evaluate = function(ast)
    if not ast then
        error("Tried to evaluate nil")
    end
    if type(ast) ~= "table" then 
        error("Tried to evaluate a non-table: " .. inspect(ast))
    end
    local rule = ast.rule:lower()
    local rule_eval = ast_traverse[rule]
    if not rule_eval then
        error("No evaluation function for '" .. rule .. "'")
    else
        local result = rule_eval(ast)
        if not result then 
            error("AST Node '" .. rule .. "' does not return a value")
        end
        return result
    end
end

-- -- res = simplify_ast(res)
-- -- print(res == nil)
-- -- show(res)
-- local result = evaluate(res)
-- -- print(inspect(result))
-- print("INPUT:")
-- local function trim(s)
--     return s:match "^%s*(.-)%s*$"
-- end
-- print(trim(code))
-- if result.text == nil then
--     error("Failed to parse")
-- end

-- local output = "dofile('h_include.lua')\n"
-- output = output .. result.text

-- print("OUTPUT:")
-- print(output)

-- local file = io.open("out.lua", "w")
-- io.output(file)
-- io.write(output)
-- io.close()

-- print("Lua result:")
local function translate_stmt(str)
    local ast, errors = pg.parse(str, grammar, printerror) 

    if errors then 
        print("Encountered one or more syntax errors. Possible solutions:")
        print(errtext)
        return
    end 

    local result = evaluate(ast)

    if result == nil or result.text == nil then
        error("Failed to parse. Maybe it's a syntax error, or maybe I'm a bad programmer.")
    end

    return result.text
end

local function translate(str, include_entry)
    local ast, errors = pg.parse(str, grammar, printerror) 

    if errors then 
        print("Encountered one or more syntax errors. Possible solutions:")
        print(errtext)
        return
    end 

    local result = evaluate(ast)

    if result == nil or result.text == nil then
        error("Failed to parse. Maybe it's a syntax error, or maybe I'm a bad programmer.")
    end

    if include_entry then
        result.text = [[
require('h_include')
]] .. result.text
    end

    result.text = [[
local __h_filename = arg[0]
local __h_slash = string.find(__h_filename, "/[^/]*$") or string.find(__h_filename, "\\[^\\]*$") or 0
local __h_current_dir = string.sub(__h_filename, 1, __h_slash - 1)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
]] .. result.text



    return result.text
end

local function translate_file(path, include_entry)
    local file = io.open(path, "r")
    if file == nil then
        error("File does not exist: " .. path)
    end
    local code = file:read("*all")
    file:close()
    local result = translate(code, include_entry)
    return result
end

local function get_folder(file)
    local lastIndexOfSlash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    local folder = stringx.sub(file, 0, lastIndexOfSlash - 1)
    return folder
end

local function scandir(directory, args)
    if not args then args = "" end
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('dir "'..directory..'" /b ' .. args)
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

local function scan_for_dirs(directory)
    return scandir(directory, "/ad")
end

local function scan_for_all(directory)
    local all = set:new(scandir(directory))
    local dirs = set:new(scan_for_dirs(directory))
    local files = all:difference(dirs)
    return dirs, files
end

local function recursive_scan(directory, d, f)
    local dirs, files = scan_for_all(directory)
    for _, v in dirs:ipairs() do
        d(directory .. "/" .. v)
        recursive_scan(directory .. "/" .. v, d, f)
    end
    for _, v in files:ipairs() do
        f(directory .. "/" .. v)
    end
end

local function compile_file(path, out, copy_h_include, include_entry)
    if not out then out = "out" end
    local lastIndexOfSlash = string.find(path, "/[^/]*$") or string.find(path, "\\[^\\]*$") or 0
    local lastIndexOfDot = string.find(path, ".[^.]*$") or (string.len(path) + 1)
    local filename = stringx.sub(path, lastIndexOfSlash + 1, lastIndexOfDot - 1)
    local text = translate_file(path, include_entry)
    os.execute("if not exist \"" .. out .. "\" mkdir \"" .. out .. "\"")
    local file = io.open(out .. "/" .. filename .. ".lua", "w")
    io.output(file)
    io.write(text)
    io.close(file)

    if copy_h_include then 
        os.execute("xcopy /y \"" .. get_folder(arg[0]) .. "/h_include\" \"" .. out .. "\" > nul")
    end

    print("\"" .. path .. "\" -> \"" .. (out .. "/" .. filename .. ".lua") .. "\" successful.");
end

local function compile_dir(dir, entry, out)
    if not entry then entry = "main.hina" end
    if not out then out = "out" end

    compile_file(dir .. "/" .. entry, out, true, true)

    local function string_startswith(s, start)
        return string.sub(s,1,string.len(start)) == start
    end

    -- in/a/b
    -- out/a/b
    local function equivalentOutDir(d)
        -- if string_startswith(dir, d) then
            return out .. string.sub(d, string.len(dir) + 1)
        -- else 
            -- return 
        -- end
    end

    recursive_scan(dir, function (d) end,
    function (f)
        if f == (dir .. "/" .. entry) then return end
        local out_dir = equivalentOutDir(f)
        compile_file(f, get_folder(out_dir), false, false)
    end)

    print("Done.")
end


-- local lfs = require("lfs")

return {
    translate = translate,
    translate_stmt = translate_stmt,
    translate_file = translate_file,
    compile_file = compile_file,
    compile_dir = compile_dir,
    evaluate_ast = evaluate,
    version = HINA_VERSION
}