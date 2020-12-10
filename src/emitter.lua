local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
output = "";
local indent; indent = 0;
emit = function(txt)
    do return 
        (function()
            txt = __h_or(txt, "");
            output = (output .. txt);
            -- Depth: 1
        end)()
    end
end
;
newline = function()
    do return 
        (function()
            emit("\n");
            __h_loop_2 = true
            for _ = 1, indent do
                if not __h_loop_2 then break end
                emit("    ")
            end
            ;
            -- Depth: 1
        end)()
    end
end
;
raise_indent = function()
    do return 
        (function()
            indent = (indent + 1);
            emit("    ");
            -- Depth: 1
        end)()
    end
end
;
lower_indent = function()
    do return 
        (function()
            indent = (indent - 1);
            output = string_trim(output);
            newline();
            -- Depth: 1
        end)()
    end
end
;
emitln = function(txt)
    do return 
        (function()
            emit(txt);
            newline();
            -- Depth: 1
        end)()
    end
end
;
remove_comma = function()
    do return 
        (function()
            output = output:sub(1, (output:len() - 2));
            -- Depth: 1
        end)()
    end
end
;
steal_output = function()
    do return 
        (function()
            local past_output; past_output = output;
            output = "";
            do return 
                past_output
            end
            ;
            -- Depth: 1
        end)()
    end
end
;
return_output = function(o)
    do return 
        (function()
            output = o;
            -- Depth: 1
        end)()
    end
end
;
capture = function(f)
    do return 
        (function()
            local op; op = steal_output();
            local result; result = f();
            local text; text = steal_output();
            return_output(op);
            do return 
                (text .. result)
            end
            ;
            -- Depth: 1
        end)()
    end
end
;
