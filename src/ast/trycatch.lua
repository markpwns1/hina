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

    local op = steal_output();

    local id = get_scope_nest();

    emitln("(function()");

    raise_indent();

    emitln((((("local __h_succ_" .. id) .. ", __h_res_") .. id) .. " = pcall(function ()"));

    raise_indent();

    (function()

      if (ast[2].rule == "expr") then

        return emit("return ")

      end

    end)();

    scopes:push({

      type = "try", 

      id = id, 

      depth = depth,

    }

    );

    emitln(evaluate(ast[2]).text);

    scopes:pop();

    lower_indent();

    emitln("end)");

    emit((((("if __h_succ_" .. id) .. " then return __h_res_") .. id) .. " "));

    (function()

      if (ast[3] == "else") then

        return (function()

          emitln("else");

          raise_indent();

          local offset = 0;

          (function()

            if (ast[4] == "with") then

              return (function()

                emitln(((("local " .. ast[5][1]) .. " = __h_res_") .. id));

                offset = (offset + 2);

                -- Depth: 3

              end)()

            end

          end)();

          emit("return ");

          scopes:push({

            type = "catch", 

            id = id, 

            depth = depth,

          }

          );

          (function()

            if (ast[(4 + offset)] == ",") then

              return (function()

                offset = (offset + 1);

                -- Depth: 3

              end)()

            end

          end)();

          emitln(evaluate(ast[(4 + offset)]).text);

          scopes:pop();

          lower_indent();

          -- Depth: 2

        end)()

      end

    end)();

    emitln("end");

    lower_indent();

    emitln("end)()");

    local text = steal_output();

    return_output(op);

    do return {

      text = text, 

      h_type = "any",

    }

     end

    ;

    -- Depth: 1

  end)()

end

 end

;
