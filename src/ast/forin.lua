local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
do return function(ast)

  return (function()

    local collection = capture(function()

      return evaluate(ast[4]).text

    end

    );

    local id = get_scope_nest();

    scopes:push({

      type = "loop", 

      id = id, 

      depth = depth,

    }

    );

    local body = capture(function()

      return evaluate((function()

        if (ast[5] == ",") then

          return ast[6]

        else

          return ast[5]

        end

      end)()

      ).text

    end

    );

    scopes:pop();

    local parent_block = get_parent_block();

    emitln((("local __h_loop_" .. id) .. " = true"));

    emit("for ");

    parse_field_list(ast[2], function(x)

      return emit((x[1] .. ", "))

    end

    );

    remove_comma();

    emit(((" in " .. collection) .. " do"));

    raise_indent();

    emitln((("if not __h_loop_" .. id) .. " then break end"));

    emitln(body);

    check_return(parent_block);

    lower_indent();

    emitln("end");

    do return void end

    ;

    -- Depth: 1

  end)()

end

 end

;
