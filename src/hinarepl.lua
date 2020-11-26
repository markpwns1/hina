local __h_filename = arg[0]
local __h_slash = string.find(__h_filename, "/[^/]*$") or string.find(__h_filename, "\\[^\\]*$") or 0
local __h_current_dir = string.sub(__h_filename, 1, __h_slash - 1)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"

local hina = require("hina")

local running = true

function quit()
    running = false
end

print("Hina " .. hina.version .. " -- REPL")

while running do
    io.write(">>> ")
    local input = io.read()

    pcall(function ()
        local translated = hina.translate_stmt(input)
        local code = load(translated)
        local success, result = pcall(code)
        print(result)
    end)
end