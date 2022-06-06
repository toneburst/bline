--[[
Bline Output Module
Crow X0X Heart Output
]]--

local deviceName = "Crow X0X Heart"

local CrowX0X = {}

CrowX0X.previousSlide = false

-- Debug mode toggle
CrowX0X.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function CrowX0X.addParams()

	print("Adding params")

	params:add_group("Crow X0X Output", 1)

	params:add_option(
		"output_crow_x0x_octave",
		"Octave-Shift",
		{"-1", "0", "+1"},
		2
	)
    params:set_action(
		"output_crow_x0x_octave",
		function(x)
			SCREEN_DIRTY = true
		end
	)

	-- Hide param group
	params:hide("Crow X0X Output")

	-- Rebuild params table
	_menu.rebuild_params()

end -- End CrowX0X.addParams()

--------------------------------------------------
-- Crow Output Functions -------------------------
--------------------------------------------------

function CrowX0X.crow_send_cv(volts)
  crow.output[1].volts = volts
end

function CrowX0X.crow_send_gate_on()
  crow.output[2].volts = 5
end

function CrowX0X.crow_send_gate_off()
  crow.output[2].volts = 0
end

function CrowX0X.crow_send_accent_on()
  crow.output[3].volts = 5
end

function CrowX0X.crow_send_accent_off()
  crow.output[3].volts = 0
end

function CrowX0X.crow_send_slide_on()
  crow.output[4].volts = 5
end

function CrowX0X.crow_send_slide_off()
  crow.output[4].volts = 0
end

--------------------------------------------------
-- Note-On Function ------------------------------
--------------------------------------------------

function CrowX0X.noteOn(note, accent, slide, rest)

	-- Set Crow CV output
	CrowX0X.crow_send_cv(note / 12)

	-- Set Accent
	if (accent) then
		CrowX0X.crow_send_accent_on()
	else
		CrowX0X.crow_send_accent_off()
	end

	-- Set Slide
	if (slide) then
		CrowX0X.crow_send_slide_on()
	else
		CrowX0X.crow_send_slide_off()
	end

	-- Set note Gate
	CrowX0X.crow_send_gate_on()

	-- Update previous note slide flag
	CrowX0X.previousSlide = slide

end -- End CrowX0X.noteOn(note, velocity)

--------------------------------------------------
-- Note-Off Function -----------------------------
--------------------------------------------------

function CrowX0X.noteOff(note, overlap)

	-- Don't turn off gate if this is an overlapping note
	if (not overlap) then
		CrowX0X.crow_send_gate_off()
	end

end -- End CrowX0X.noteOff(note, accent, slide)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function CrowX0X.allNotesOff()

end -- End CrowX0X.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function CrowX0X.unload()

	print("Unloading Output module '" .. deviceName .. "'")

	-- Hide param group
	params:hide("Crow X0X Output")

	-- Rebuild params table
	_menu.rebuild_params()

	-- All-notes-off
	CrowX0X.allNotesOff()

end -- End CrowX0X.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function CrowX0X.activate()

	print("Activating Output module '" .. deviceName .. "'")

	-- Unhide param group
	params:show("Crow X0X Output")

	-- Turn off Crow clock output and hide menu items
	params:set("clock_crow_out", 1) -- sets 'crow out' to 'off'
	params:hide("clock_crow_out") -- hide the 'crow out' param
	params:hide("clock_crow_out_div") -- hide the 'crow out div' param
	params:hide("clock_crow_in_div") -- hide the 'crow in div' param

	-- Rebuild params table
	_menu.rebuild_params()

end -- End CrowX0X.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function CrowX0X.init(debug)

    print("Initialising Output module '" .. deviceName .. "'")

	if (debug == true) then
		CrowX0X.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    CrowX0X.addParams()

	-- All-notes-off
	CrowX0X.allNotesOff()

end -- End CrowX0X.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return CrowX0X
