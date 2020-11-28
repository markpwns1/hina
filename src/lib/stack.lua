--[[
  stack.lua
 
  This Lua class implementation of a stack data structure was based on Mário Kašuba's function 
  in the book, Lua Game Development Cookbook (2015)
 
]]
 
local Stack = {}
Stack.__index = Stack

local function new()
    local n = setmetatable({}, Stack)
    n:init()
    return n
end
 
function Stack:init(list)
 
  if not list then
    -- create an empty stack
    self.stack = {}
  else
    -- initialise the stack
    self.stack = list
  end
end
 
function Stack:push(item)
  -- put an item on the stack
  self.stack[#self.stack+1] = item
end
 
function Stack:pop()
  -- make sure there's something to pop off the stack
  if #self.stack > 0 then
    -- remove item (pop) from stack and return item
    return table.remove(self.stack, #self.stack)
  end
end

function Stack:peek(i)
    if not i then i = 0 end
    return self.stack[#self.stack - i]
end

function Stack:len()
    return #self.stack
end
 
function Stack:iterator()
  -- wrap the pop method in a function
  return function()
    -- call pop to iterate through all items on a stack
    return self:pop()
  end
end

return new