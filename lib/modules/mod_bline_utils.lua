------------------------
-- Bline Utils Module --
------------------------

local Bline_Utils = {}

------------------------------------------
-- Print pattern array (debug function) --
------------------------------------------

function Bline_Utils.printPattern(label, pattern)

  p = label
  p = p .. ": {"
  for i = 1, 16, 1
  do
    p = p .. tostring(pattern[i]) .. ","
  end
  p = p .. "}"
  print(p)

end -- End print_pattern()

------------------------------------------
-- Get table to values label strings -----
------------------------------------------

--[[
For indexed table of form

tab = {
	{
		thekey = "blah 1",
		etc.
	},
	{
		thekey = "blah 2",
		etc.
	},
	etc.
}

...return a table containing the values of the key "thekey" for each item
]]--

function Bline_Utils.getKeyVals(tabl, key)

	-- Declare empty table for items
	local items = {}

	-- Loop through indexed items in table
	for i, item in ipairs(tabl) do
		table.insert(items, item[key])
	end
	return items

end -- End Bline_Utils.get_keyVals(tab, key)

return Bline_Utils
