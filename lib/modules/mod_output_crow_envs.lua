--[[
Bline Output Module
Crow Note CV / VCA / VCF Cutoff Envelopes Output
]]--

local deviceName = "Crow Envelopes"

local CrowEnvs = {}

-- Debug mode toggle
CrowEnvs.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function CrowEnvs.addParams()

	print("Adding params")

	params:add_group("Crow Envs Output", 1)

	params:add_option("output_crow_envs_octave", "Octave-Shift", {"-1", "0", "+1"}, 2)
    params:set_action("output_crow_envs_octave", function(x) SCREEN_DIRTY = true end)

	-- Hide param group
	params:hide("Crow Envs Output")

	-- Rebuild params table
	_menu.rebuild_params()

end -- End CrowEnvs.addParams()

--------------------------------------------------
-- Note-On Function ------------------------------
--------------------------------------------------

function CrowEnvs.noteOn(note, accent, slide)

    -- Velocity (Accent ON/OFF)
    local velocity = 100
    if accent then
        velocity = 127
    end

end -- End CrowEnvs.noteOn(note, velocity)

--------------------------------------------------
-- Note-Off Function -----------------------------
--------------------------------------------------

function CrowEnvs.noteOff(note, accent, slide)

end -- End CrowEnvs.noteOff(note, accent, slide)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function CrowEnvs.allNotesOff()

end -- End CrowEnvs.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function CrowEnvs.unload()

	print("Unloading Output module '" .. deviceName .. "'")

	-- Hide param group
	params:hide("Crow Envs Output")

	-- Rebuild params table
	_menu.rebuild_params()

	-- All-notes-off
	CrowEnvs.allNotesOff()

end -- End CrowEnvs.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function CrowEnvs.activate()

	print("Activating Output module '" .. deviceName .. "'")

	-- Unhide param group
	params:show("Crow Envs Output")

	-- Rebuild params table
	_menu.rebuild_params()

end -- End CrowEnvs.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function CrowEnvs.init(debug)

    print("Initialising Output module '" .. deviceName .. "'")

	if (debug == true) then
		CrowEnvs.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    CrowEnvs.addParams()

	-- All-notes-off
	CrowEnvs.allNotesOff()

end -- End CrowEnvs.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return CrowEnvs
