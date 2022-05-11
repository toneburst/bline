------------------------
-- Bline Utils Module --
------------------------

local Bline_Utils = {}

------------------------------------------
-- Print pattern array (debug function) --
------------------------------------------

function Bline_Utils.print_pattern(label, pattern)

  p = label
  p = p .. ": {"
  for i = 1, 16, 1
  do
    p = p .. tostring(pattern[i]) .. ","
  end
  p = p .. "}"
  print(p)

end -- End print_pattern()

return Bline_Utils
