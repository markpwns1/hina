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
            local op; op = steal_output();
            emitln("{");
            raise_indent();
            local items; items = ast[2];
            local i; i = 1;
            local __h_loop_2 = true
            while __h_loop_2 and (items[i]) do
                (function()
                    local item; item = items[i];
                    local name; name = item[1][1];
                    local val; val = item[3];
                    emitln((((name .. " = ") .. evaluate(val).text) .. ", "));
                    i = (i + 2);
                    -- Depth: 2
                end)()
            end
            ;
            remove_comma();
            lower_indent();
            emitln("}");
            local text; text = steal_output();
            return_output(op);
            do return 
                {
                text = text, 
                h_type = "any",
            }
            end
            ;
            -- Depth: 1
        end)()
    end
end
end
;
