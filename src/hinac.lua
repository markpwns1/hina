local __h_filename = arg[0]
local __h_slash = string.find(__h_filename, "/[^/]*$") or string.find(__h_filename, "\\[^\\]*$") or 0
local __h_current_dir = string.sub(__h_filename, 1, __h_slash - 1)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"

local hina = require("hina")
local argparse = require("lib.argparse")
local parser = argparse("hinac", "Compile Hina code to Lua code.")
parser:option("-d --directory", "The directory to be compiled"):args(1)
parser:option("-e --entry", "The entry point of the Hina program"):args(1):default("main.hina")
parser:option("-o --output", "The folder in which to write the compiled Lua files"):args(1):default("out")
parser:option("--no-include", "Does not copy h_include, required for all Hina programs"):args(0)
local args = parser:parse()
-- show(args)
if args.directory then
    hina.compile_dir(args.directory, args.entry, args.output)
else 
    hina.compile_file(args.entry, args.output, not args.no_headers, true)
end
