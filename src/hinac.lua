local __h_filename = arg[0]
local __h_slash = string.find(__h_filename, "/[^/]*$") or string.find(__h_filename, "\\[^\\]*$") or 0
local __h_current_dir = string.sub(__h_filename, 1, __h_slash - 1)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"

local hina = require("hina")
local argparse = require("lib.argparse")
local parser = argparse("hinac", "Compile Hina code to Lua code.")
parser:argument("input", "The Hina file to be compiled")
parser:argument("output", "The folder in which to write the compiled Lua files"):default("out")
parser:option("-c --copyhina", "Copies the Hina standard library"):args(0)
local args = parser:parse()
-- show(args)
hina.compile_file(args.input, args.output, args.copyhina)
