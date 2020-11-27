local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
require('h_include')
do return function(ast)
  return (function()
    local capture_eval = function(v)
      return capture(function()
        return (function()
          local n = evaluate(v);
          assert_type(n.h_type, [[num]]);
          do return n.text end
          ;
          -- Depth: 2
        end)()
      end
      )
    end
    ;
    local _from = capture_eval(ast[2]);
    local _to = capture_eval(ast[4]);
    local offset = 0;
    local _by;
    (function()
      if (ast[5] == [[by]]) then
        return (function()
          _by = capture_eval(ast[6]);
          offset = 2;
          -- Depth: 2
        end)()
      end
    end)();
    local var_name;
    (function()
      if (ast[(5 + offset)] == [[with]]) then
        return (function()
          var_name = ast[(6 + offset)][1];
          offset = (offset + 2);
          -- Depth: 2
        end)()
      end
    end)();
    offset = (offset + (function()
      if (ast[(5 + offset)] == [[,]]) then
        return 1
      else
        return 0
      end
    end)()
    );
    local id = get_scope_nest();
    scopes:push({
      type = [[loop]], 
      id = id, 
      depth = depth,
    }
    );
    raise_indent();
    local body = capture(function()
      return evaluate(ast[(5 + offset)]).text
    end
    );
    lower_indent();
    scopes:pop();
    local parent_block = get_parent_block();
    emitln((([[__h_loop_]] .. id) .. [[ = true]]));
    emit(((((([[for ]] .. __h_or(var_name, [[_]])) .. [[ = ]]) .. _from) .. [[, ]]) .. _to));
    (function()
      if _by then
        return emit(([[, ]] .. _by))
      end
    end)();
    emitln([[ do]]);
    raise_indent();
    emitln((([[if not __h_loop_]] .. id) .. [[ then break end]]));
    emit(body);
    check_return(parent_block);
    lower_indent();
    emitln([[end]]);
    do return void end
    ;
    -- Depth: 1
  end)()
end
 end
;
