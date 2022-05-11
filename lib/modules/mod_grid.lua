--[[
Bline Grid Module

With midigrid support.
]]--

-- midigrid support
-- https://norns.community/authors/jaggednz/midigrid
local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
