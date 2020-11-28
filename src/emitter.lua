local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
output = "";
local indent = 0;
emit = function(txt)

  return (function()

    txt = __h_or(txt, "");

    output = (output .. txt);

    -- Depth: 1

  end)()

end

;
newline = function()

  return (function()

    emit("\
\
");

    __h_loop_2 = true

    for _ = 1, indent do

      if not __h_loop_2 then break end

      emit("  ")

    end

    ;

    -- Depth: 1

  end)()

end

;
raise_indent = function()

  return (function()

    indent = (indent + 1);

    emit("  ");

    -- Depth: 1

  end)()

end

;
lower_indent = function()

  return (function()

    indent = (indent - 1);

    output = string_trim(output);

    newline();

    -- Depth: 1

  end)()

end

;
emitln = function(txt)

  return (function()

    emit(txt);

    newline();

    -- Depth: 1

  end)()

end

;
remove_comma = function()

  return (function()

    output = output:sub(1, (output:len() - 2));

    -- Depth: 1

  end)()

end

;
steal_output = function()

  return (function()

    local past_output = output;

    output = "";

    do return past_output end

    ;

    -- Depth: 1

  end)()

end

;
return_output = function(o)

  return (function()

    output = o;

    -- Depth: 1

  end)()

end

;
capture = function(f)

  return (function()

    local op = steal_output();

    local result = f();

    local text = steal_output();

    return_output(op);

    do return (text .. result) end

    ;

    -- Depth: 1

  end)()

end

;
