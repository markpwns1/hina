local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
require('h_include')
do return 
    function(ast)
    do return 
        (function()
            local pc; pc = 1;
            local __h_loop_2 = true
            while __h_loop_2 and (ast[pc]) do
                (function()
                    (function()
                        if (ast[pc] ~= ";") then
                            do return emit((string_trim(evaluate(ast[pc]).text) .. ";\n"))
                            end
                        end
                    end)();
                    pc = (pc + 1);
                    -- Depth: 2
                end)()
            end
            ;
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
