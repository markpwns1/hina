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
            parse_field_list(ast[1], function(x)
                do return 
                    (function()
                        local eva; eva = evaluate(x);
                        (function()
                            if eva.ends_with_call then
                                do return error("Cannot assign directly to the result of a function")
                                end
                            end
                        end)();
                        emit((eva.text .. ", "));
                        -- Depth: 2
                    end)()
                end
            end
            );
            remove_comma();
            emit(" = ");
            parse_field_list(ast[3], function(x)
                do return 
                    emit((evaluate(x).text .. ", "))
                end
            end
            );
            remove_comma();
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
