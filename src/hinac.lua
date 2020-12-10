local function __h_dir(file)
    local slash = string.find(file, "/[^/]*$") or string.find(file, "\\[^\\]*$") or 0
    return string.sub(file, 1, slash - 1)
end
local __h_filename = __h_dir(arg[0]) .. "/" .. string.gsub(... or "dummy", "%.", "/")
local __h_current_dir = __h_dir(__h_filename)
package.path = package.path .. ";" .. __h_current_dir .. "\\?.lua"
package.cpath = package.cpath .. ";" .. __h_current_dir .. "\\?.dll"
local hina; hina = require("hina");
local argparse; argparse = require("lib.argparse");
local parser; parser = argparse("hinac", "Compile Hina code to Lua code.");
parser:option("-d --directory", "The directory to be compiled"):args(1);
parser:option("-e --entry", "The entry point of the Hina program"):args(1):default("main.hina");
parser:option("-o --output", "The folder in which to write the compiled Lua files"):args(1):default("out");
parser:option("-m --min", "Does not copy any of the required header files for Hina programs"):args(0);
local args; args = parser:parse();
(function()
    if args.directory then
        do return hina.compile_dir(args.directory, args.entry, args.output)
        end
    end
end)();
