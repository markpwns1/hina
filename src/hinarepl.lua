local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
local hina = require([[hina]]);
local running = true;
quit = function()
  return (function()
    running = false;
    -- Depth: 1
  end)()
end
;
print((([[Hina ]] .. hina.version) .. [[ -- REPL]]));
print([[Call quit(); to exit]]);
local __h_loop_0 = true
while __h_loop_0 and (running) do
  (function()
    io.write([[>>> ]]);
    local input = io.read();
    (function()
      local __h_succ_2, __h_res_2 = pcall(function ()
        return (function()
          local translated = hina.translate_stmt(input);
          local module = load(translated);
          print((function()
            local __h_succ_4, __h_res_4 = pcall(function ()
              return module()
            end)
            if __h_succ_4 then return __h_res_4 else
              local err = __h_res_4
              return err
            end
          end)()
          );
          -- Depth: 2
        end)()
      end)
      if __h_succ_2 then return __h_res_2 else
        local err = __h_res_2
        return print(string_trim(err))
      end
    end)();
    -- Depth: 1
  end)()
end
;
