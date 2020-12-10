local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
do return 
    function(ast)
    do return 
        (function()
            local offset; offset = (function()
                if (ast[3] == ",") then
                    do return 1
                    end
                else
                    do return 
                        0
                    end
                end
            end)()
            ;
            local id; id = get_scope_nest();
            local parent_block; parent_block = get_parent_block();
            emitln((("local __h_loop_" .. id) .. " = true"));
            emit((("while __h_loop_" .. id) .. " and ("));
            local cond; cond = evaluate(ast[2]);
            assert_type(cond.h_type, "bool");
            emit(cond.text);
            emitln(") do");
            raise_indent();
            scopes:push({
                type = "loop", 
                id = id, 
                depth = depth,
            }
            );
            local body; body = evaluate(ast[(3 + offset)]);
            scopes:pop();
            emitln(body.text);
            check_return(parent_block);
            lower_indent();
            emitln("end");
            do return 
                void
            end
            ;
            -- Depth: 1
        end)()
    end
end
end
;
