output = ""

local indent = 0

function emit(txt)
    txt = txt or ""
    output = output .. txt
end

local function newline()
    emit("\n")
    for _ = 1, indent do
        emit("  ")
    end
end

function raise_indent()
    indent = indent + 1
    emit("  ")
end

function lower_indent()
    indent = indent - 1
    output = string_trim(output)
    newline()
end

function emitln(txt)
    emit(txt)
    newline()
end

function remove_comma()
    output = output:sub(1, output:len() - 2) 
end

function steal_output()
    local past_output = output
    output = ""
    return past_output
end

function return_output(o)
    output = o
end