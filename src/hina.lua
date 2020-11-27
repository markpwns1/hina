-- local oldRequire = require
-- require = function (p)
--     oldRequire("src." .. p)
-- end
-- -- local x = require("lpeglabel")
require("util")

local HINA_VERSION = "pre-0.1.1"

local pg = require("lib.parser-gen.parser-gen")

require("emitter")

local Stack = require("stack")
local tablex = require("lib.tablex")
local stringx = require("lib.stringx")
local set = require("lib.set")

local parse = require("parser")
-- pg.usenodes(true)
depth = 0
scopes = Stack()
local return_commands = { }

void = { text = "", h_type = "void" };

function get_scope_nest()
    return scopes:len()
end

evaluate = nil
local function type_compatible(a, b)
    assert(a ~= nil, "Left type is null")
    assert(b ~= nil, "Right type is null")
    return a == "any" or b == "any" or a == b
end

function assert_type(a, b)
    if not type_compatible(a, b) then
        error("Expected object of type " .. inspect(b) .. " but got " .. inspect(a))
    end
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

function parse_field_list(list, f, start)
    if not start then start = 1 end
    local i = start
    while list[i] do
        f(list[i])
        i = i + 2
    end
end

function get_parent_block()
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

function check_return(block_name)
    if tablex.index_of(return_commands, block_name) ~= nil then
        -- show(return_commands)
        tablex.remove_value(return_commands, block_name)
        -- show(return_commands)
        emitln("if __h_return_value_" .. block_name .. " then")
        raise_indent()
        emitln("local __h_temp = __h_return_value_" .. block_name)
        emitln("__h_return_value_" .. block_name .. " = nil")
        emitln("return __h_unpack(__h_temp)")
        lower_indent()
        emitln("end")
    end
end

local unbox_ast = generate_unboxer(1)

local ast_traverse = {
    program = function(ast)
        local pc = 1
        while ast[pc] do
            if ast[pc] ~= ";" then
                emit(string_trim(evaluate(ast[pc]).text) .. ";\n")
            end
            pc = pc + 1
        end
        return void
    end,
    comment = function (ast) return void end,
    stmt = function(ast)
        -- if ast[1].rule == "expr" and ast[1][1] and ast[1][1] then
        --     error("Expression used as statement")  
        -- end
        return unbox_ast(ast)
    end,
    assignment = function (ast)
        parse_field_list(ast[1], function (x)
            local eva = evaluate(x)
            if eva.ends_with_call then
                error("Cannot assign directly to the result of a function")
            end
            emit(eva.text .. ", ")
        end)
        remove_comma()

        emit(" = ")

        parse_field_list(ast[3], function (x)
            emit(evaluate(x).text .. ", ")
        end)
        remove_comma()

        return void
    end,
    tuple = function (ast)
        -- show(ast)
        local i = 2
        while ast[i] do 
            emit(evaluate(ast[i]).text .. ternary(ast[i + 2], ", ", ""))
            i = i + 2
        end
        return void
    end,
    multi_ret = function (ast)
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
            emitln("__h_return_value_" .. scope_name .. " = __h_pack(" .. val.text .. ")")
        end

        l()
        i = i + 2
        while ast[i] do
            l()
            i = i + 2
        end

        emitln("do return __h_unpack(__h_return_value_" .. scopes:peek().name .. ") end")
        return void
    end,
    continue_stmt = function(ast)
        if ast[2] and ast[2].rule == "block_name" then
            
            local block_name = ast[2][2][1]
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot return past a function scope")
                end

                -- print(s.type)
                
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    emitln("__h_return_value_" .. s.name .. " = __h_pack(nil)")
                    
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
                    emitln("__h_loop_" .. s.id .. " = false")
                end
                i = i + 1
            end

            emitln("do return __h_unpack(__h_return_value_" .. block_name .. ") end")
            return void
        else
            local parent = scopes:peek(1)
            if parent and parent.type == "loop" then
                emitln("__h_loop_" .. parent.id .. " = false")
            end
            emitln("do return end")
            return void
        end
    end,
    break_stmt = function(ast)
        if ast[2] and ast[2].rule == "block_name" then
            local block_name = ast[2][2][1]
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot break past a function scope")
                end

                -- print(s.type)
                
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    emitln("__h_return_value_" .. s.name .. " = __h_pack(nil)")
                    
                    if s.name == block_name then 
                        local parent = scopes:peek(i + 1)
                        if parent and parent.type == "loop" then
                            emitln("__h_loop_" .. parent.id .. " = false")
                        end
                        break 
                    end
                elseif s.type == "loop" then 
                    emitln("__h_loop_" .. s.id .. " = false")
                end
                i = i + 1
            end

            emitln("do return __h_unpack(__h_return_value_" .. block_name .. ") end")
            return void
        else
            local parent = scopes:peek(1)
            local grandparent = scopes:peek(2)
            if parent and parent.type == "loop" then
                emitln("__h_loop_" .. parent.id .. " = false")
            elseif  grandparent and grandparent.type == "loop" then
                emitln("__h_loop_" .. grandparent.id .. " = false")
            end
            emitln("do return end")
            return void
        end
    end,
    ret = function (ast)
        if ast[1].rule == "block_name" then
            
            local block_name = ast[1][2][1]
            local val = ternary(ast[3] == ".", "nil", nil)
            -- show(ast[3]);
            val = val or evaluate(ast[3])
            local i = 0
            while i < scopes:len() do
                local s = scopes:peek(i)
                if s.type == "func" then
                    error("Cannot return past a function scope")
                end
                if s.type == "block" then 
                    table.insert(return_commands, s.name)
                    emitln("__h_return_value_" .. s.name .. " = __h_pack(" .. ((val and val.text) or "nil") .. ")")

                    if s.name == block_name then 
                        local parent = scopes:peek(i + 1)
                        if parent and parent.type == "loop" then
                            emitln("__h_loop_" .. parent.id .. " = false")
                        end
                        break 
                    end
                elseif s.type == "loop" then 
                    emitln("__h_loop_" .. s.id .. " = false")
                end
                i = i + 1
            end

            emitln("do return __h_unpack(__h_return_value_" .. block_name .. ") end")
            return void
        else
            local parent = scopes:peek(1)
            local grandparent = scopes:peek(2)
            if parent and parent.type == "loop" then
                emitln("__h_loop_" .. parent.id .. " = false")
            elseif  grandparent and grandparent.type == "loop" then
                emitln("__h_loop_" .. grandparent.id .. " = false")
            end
            
            local val = ternary(ast[2] == ".", "nil", nil)
            if ast[2] then
                val = val or evaluate(ast[2])
            end
            emitln("do return " .. ((val and val.text) or "nil") .. " end")
            return void
        end
    end,
    var_dec = function (ast)
        -- show(ast)
        local names = ast[2]
        emit("local ")
        local i = 1
        while names[i] do
            emit(names[i][1] .. ternary(names[i + 2], ", ", ""))
            i = i + 2
        end
        if ast[3] then
            emit(" = ")
            parse_field_list(ast[4], function (x)
                emit(evaluate(x).text .. ", ")
            end)
            remove_comma()
        end
        return void
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
    exp = generate_binop("num", "num", "num"),
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
        local op = steal_output()
        emitln("(function()")
        raise_indent()

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
            emit(string_trim(evaluate(statements[pc]).text) .. ";")

            check_return(block_name)

            if statements[pc + 1] then
                emitln()
            end

            pc = pc + 2
        end

        scopes:pop()
        depth = depth - 1

        emitln(block_annotation)
        lower_indent()
        emitln("end)()")

        local text = steal_output()
        return_output(op)
        return {
            text = text,
            h_type = "any"
        }
    end,
    --[[for_loop = function (ast)
        local from = capture(function ()
            local n = evaluate(ast[2])
            assert_type(n.h_type, "num")
            return n.text
        end)

        local to = capture(function ()
            local n = evaluate(ast[4])
            assert_type(n.h_type, "num")
            return n.text
        end)

        local offset = 0
        local by
        if ast[5] == "by" then
            by = capture(function () 
                local n = evaluate(ast[6])
                assert_type(n.h_type, "num")
                return n.text
            end)
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

        local body = capture(function () return evaluate(ast[5 + offset]).text end)

        scopes:pop()

        local parent_block = get_parent_block()

        emitln("__h_loop_" .. id .. " = true")
        emit("for " .. ternary(var_name, var_name, "_") .. " = " .. from 
            .. ", " .. to)
        if by then
            emit(", " .. by)
        end
        emitln(" do")
        emitln("if not __h_loop_" .. id .. " then break end")
        emitln(body)
        check_return(parent_block)
        emitln("end")

        return void
    end,]]
    for_loop = require("ast.forloop"),
    for_in_loop = require("ast.forin"),
    try_catch_expr = require("ast.trycatch"),
    -- for_in_loop = function (ast)
    --     local collection = evaluate(ast[4])
        
    --     local id = get_scope_nest() 
    --     scopes:push({
    --         type = "loop",
    --         id = id,
    --         depth = depth
    --     })

    --     local body = evaluate(ternary(ast[5] == ",", ast[6], ast[5]))

    --     scopes:pop()
        
    --     local parent_block = get_parent_block()

    --     emitln("local __h_loop_" .. id .. " = true")
    --     emit("for ")

    --     parse_field_list(ast[2], function (x)
    --         emit(x[1] .. ", ")
    --     end)

    --     remove_comma()
        
    --     emit(" in " .. collection.text .. " do")
    --     raise_indent()
    --     emitln("if not __h_loop_" .. id .. " then break end")
    --     emitln(body.text)
    --     check_return(parent_block)
    --     lower_indent()
    --     emitln("end")

    --     return void
    -- end,
    while_loop = function (ast)

        local offset = ternary(ast[3] == ",", 1, 0)
        local id = get_scope_nest() 

        local parent_block = get_parent_block()

        emitln("local __h_loop_" .. id .. " = true")
        emit("while __h_loop_" .. id .. " and (")
        local cond = evaluate(ast[2])
        assert_type(cond.h_type, "bool")
        emit(cond.text)
        emitln(") do")
        raise_indent()

        scopes:push({
            type = "loop",
            id = id,
            depth = depth
        })
        local body = evaluate(ast[3 + offset])
        scopes:pop()

        emitln(body.text)
        check_return(parent_block)
        lower_indent()
        emitln("end")
        return void
    end,
    if_expr = function (ast)
        local op = steal_output()
        
        emitln("(function()")
        raise_indent()

        emit("if ")
        local cond = evaluate(ast[2])
        emit(cond.text)
        emitln(" then")
        raise_indent()

        local offset = ternary(ast[3] == ",", 1, 0)

        scopes:push({
            type = "if",
            depth = depth
        })

        if ast[3 + offset].rule == "expr" then
            emit("return ")
        end

        local if_true = evaluate(ast[3 + offset])
        assert_type(cond.h_type, "bool")
        emitln(if_true.text)

        lower_indent()
        if ast[5 + offset] then
            emitln("else")
            raise_indent()
            local if_false = evaluate(ast[5 + offset])
            if ast[5 + offset].rule == "expr" then
                emit("return ")
            end
            emitln(if_false.text)
            lower_indent()
        end

        scopes:pop()
        
        emitln("end")
        lower_indent()
        emitln("end)()")

        local parent_block = get_parent_block()
        check_return(parent_block)
        -- text = text .. "if __h_return_value_" .. depth .. " then"
        -- text = new_indent(text)
        -- text = text .. "local __h_temp = __h_return_value_" .. depth
        -- text = newline(text)
        -- text = text .. "return __h_temp"
        -- text = end_indent(text)
        -- text = text .. "end"
        local text = steal_output()
        return_output(op)
        return {
            text = text,
            h_type = "any"
        }
    end,
    func = function (ast)
        local op = steal_output()

        local args = ast[2]
        local offset = -1

        local is_penis_function = ast[4 + ternary(args ~= ")", 0, -1)] == ":"
        if is_penis_function then
            emit("function(self, ")
        else 
            emit("function(")
        end

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
                emit(ternary(is_vararg, "...", name .. ternary(args[i + 2], ", ", "")))
                i = i + 2
            end
            offset = 0
        elseif is_penis_function then
            remove_comma()
        end
        emitln(")")
        raise_indent()
        if vararg_name then
            emitln("local " .. vararg_name .. " = { ... }")
        end
        scopes:push({
            type = "func",
            depth = depth
        })

        -- show(ast)
        if ast[4 + offset] == ":" then
            offset = offset + 1 
        end
        -- show(5 + offset)
        local val = ast[5 + offset]
        if val == "." then
            emitln("return nil")
        else 
            -- print("spot: " .. (5 + offset))
            -- show(ast)
            if val == nil then
                error("Expected expression after '=>' in a function")
            end

            emitln("return " .. evaluate(val).text)
        end
        scopes:pop()
        lower_indent()
        emitln("end")

        local text = steal_output()
        return_output(op)

        return {
            text = text,
            h_type = "func"
        }
    end,
    table = function (ast)
        local op = steal_output()
        emitln("{")
        raise_indent()
        local items = ast[2]
        local i = 1
        while items[i] do
            local item = items[i]
            -- show(item)
            local name = item[1][1]
            local val = item[3]
            -- show()
            emitln(name .. " = " .. evaluate(val).text .. ", ")
            i = i + 2
        end
        remove_comma()
        lower_indent()
        emitln("}")
        local text = steal_output()
        return_output(op)
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

local function translate_stmt(str)
    local parsed = parse(str)

    if parsed.errors then 
        error("Encountered one or more syntax errors. Possible solutions:\n" .. parsed.error_text)
        return
    end 

    steal_output()
    local result = evaluate(parsed.ast)

    if result == nil or result.text == nil then
        error("Failed to parse. Maybe it's a syntax error, or maybe I'm a bad programmer.")
    end

    return output
end

local function translate(str, include_entry)
    local text = translate_stmt(str)

    if include_entry then
        text = [[
require('h_include')
]] .. text
    end

    text = [[
local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
]] .. text

    return text
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

    -- in/a/b
    -- out/a/b
    local function equivalentOutDir(d)
        -- if string_startswith(dir, d) then
            return out .. string.sub(d, string.len(dir) + 1)
        -- else 
            -- return 
        -- end
    end

    compile_file(dir .. "/" .. entry, get_folder(equivalentOutDir(dir .. "/" .. entry)), true, true)

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
    evaluate_ast = function (ast)
        steal_output()
        evaluate(ast)
        return output
    end,
    version = HINA_VERSION
}