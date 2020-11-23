function __h_not(x)
    if x and type(x) == "table" and x.__not then return x.__not() else return not x end
end

function __h_or(x, y)
    if x and type(x) == "table" and x.__or then return x.__or(y) else return x or y end
end

function __h_and(x, y)
    if x and type(x) == "table" and x.__and then return x.__and(y) else return x and y end
end

function __h_pack(...)
    return { ... }
end

local up = unpack or table.unpack
function __h_unpack(x)
    if type(x) == "table" then return up(x) else return x end
end

__h_return_value = nil