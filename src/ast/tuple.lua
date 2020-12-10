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
            local i; i = 2;
            local __h_loop_2 = true
            while __h_loop_2 and (ast[i]) do
                (function()
                    emit((evaluate(ast[i]).text .. (function()
                        if ast[(i + 2)] then
                            do return ", "
                            end
                        else
                            do return 
                                ""
                            end
                        end
                    end)()
                    ));
                    i = (i + 2);
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
