inspect = require("lib.inspect")

function ternary(cond, t, f)
    if cond then return t else return f end
end

function show(x)
    print(inspect(x))
end

function string_trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string_startswith(s, start)
    return string.sub(s,1,string.len(start)) == start
end

local err = error
error = function (msg)
    err("\n" .. msg)
end