local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
inspect = require("lib.inspect");
ternary = function(cond, t, f)

  return (function()

    if cond then

      return t

    else

      return f

    end

  end)()

end

;
show = function(x)

  return print(inspect(x))

end

;
string_trim = function(s)

  return s:gsub("^%s*(.-)%s*$", "%1")

end

;
string_startswith = function(s, start)

  return (s:sub(1, start:len()) == start)

end

;
local err = error;
error = function(msg)

  return err(("\n" .. msg))

end

;
