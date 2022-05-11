--[[
Bline Quantiser Module
]]--

-- Note and Octave quantiser
-- TODO:
-- Add optional mode to take single note number and extract note and octave
-- Add custom scales

------------------------------------------
-- Includes ------------------------------
------------------------------------------

--local ControlSpec = require "controlspec"
local NornsUtils = require "lib.util"
local TabUtil = require "lib.tabutil"
local ControlSpec = require "controlspec"

------------------------------------------
-- Scale Data Tables ---------------------
------------------------------------------

-- Note names
local note_names = {}
note_names[1] = "C "
note_names[2] = "C#"
note_names[3] = "D "
note_names[4] = "D#"
note_names[5] = "E "
note_names[6] = "F "
note_names[7] = "F#"
note_names[8] = "G "
note_names[9] = "G#"
note_names[10] = "A "
note_names[11] = "A#"
note_names[12] = "B "
note_names[13] = "C "

-- Root-note names for param menu
local rootnote_names = {}
rootnote_names[1] = "-F#"
rootnote_names[2] = "-G"
rootnote_names[3] = "-G#"
rootnote_names[4] = "-A"
rootnote_names[5] = "-A#"
rootnote_names[6] = "-B"
rootnote_names[7] = "C"
rootnote_names[8] = "+C#"
rootnote_names[9] = "+D"
rootnote_names[10] = "+D#"
rootnote_names[11] = "+E"
rootnote_names[12] = "+F"
rootnote_names[13] = "+F#"

-- Root-note param transpose amounts
local note_transpose_amt = {}
note_transpose_amt[1] = -6
note_transpose_amt[2] = -5
note_transpose_amt[3] = -4
note_transpose_amt[4] = -3
note_transpose_amt[5] = -2
note_transpose_amt[6] = -1
note_transpose_amt[7] = 0 -- C
note_transpose_amt[8] = 1
note_transpose_amt[9] = 2
note_transpose_amt[10] = 3
note_transpose_amt[11] = 4
note_transpose_amt[12] = 5
note_transpose_amt[13] = 6

-- Scale tables
-- Sourced from MI MIDIPal firmware by @Pichenettes)
-- https://github.com/pichenettes/midipal
local scales = {}
scales[1] = {0,1,2,3,4,5,6,7,8,9,10,11,12}
-- scales[2] = {0,0,2,2,4,5,5,7,7,9,9,11,12}
-- scales[3] = {0,0,2,3,3,5,5,7,7,10,10,10,12}
-- scales[4] = {0,1,1,3,3,5,5,7,8,8,10,10,12}
-- scales[5] = {0,0,2,2,4,4,6,7,7,9,11,11,12}
-- scales[6] = {0,0,2,2,4,5,5,7,7,9,10,10,12}
-- scales[7] = {0,0,2,3,3,5,5,7,8,8,10,10,12}
-- scales[8] = {0,1,1,3,3,5,6,6,8,8,10,10,12}
-- scales[9] = {0,0,3,3,4,4,7,7,7,9,10,10,12}
-- scales[10] = {0,0,3,3,3,5,6,7,7,10,10,10,12}
-- scales[11] = {0,0,2,2,4,4,7,7,7,9,9,9,12}
-- scales[12] = {0,0,3,3,3,5,5,7,7,10,10,10,12}
-- scales[13] = {0,1,1,4,4,5,5,7,8,8,11,11,12}
-- scales[14] = {0,1,1,4,4,4,6,7,8,8,11,11,12}
-- scales[15] = {0,1,1,3,3,5,5,7,7,10,10,11,12}
-- scales[16] = {0,1,1,3,3,6,6,7,8,8,11,11,12}
-- scales[17] = {0,0,2,2,4,5,5,5,9,9,10,11,12}
-- scales[18] = {0,0,2,2,5,5,5,7,7,9,9,9,12}
-- scales[19] = {0,0,3,3,3,5,5,8,8,8,10,10,12}
-- scales[20] = {0,0,3,3,4,4,6,6,8,8,10,10,12}
-- scales[21] = {0,1,1,3,4,5,5,7,8,8,10,10,12}
-- scales[22] = {0,1,1,1,5,5,5,7,8,8,8,8,12}
-- scales[23] = {0,1,1,3,3,3,7,7,8,8,8,8,12}
-- scales[24] = {0,0,2,2,4,4,6,6,8,8,10,10,12}
scales[2] = {0,0,2,2,4,5,5,7,7,9,9,11,12}
scales[3] = {0,0,2,3,3,5,5,7,7,10,10,12,12}
scales[4] = {0,1,1,3,3,5,5,7,8,8,10,10,12}
scales[5] = {0,0,2,2,4,4,6,7,7,9,11,12,12}
scales[6] = {0,0,2,2,4,5,5,7,7,9,10,10,12}
scales[7] = {0,0,2,3,3,5,5,7,8,8,10,10,12}
scales[8] = {0,1,1,3,3,5,6,6,8,8,10,10,12}
scales[9] = {0,0,3,3,4,4,7,7,7,9,10,10,12}
scales[10] = {0,0,3,3,5,5,6,7,7,10,10,12,12}
scales[11] = {0,0,2,2,4,4,7,7,9,9,9,12,12}
scales[12] = {0,0,3,3,5,5,7,7,7,10,10,10,12}
scales[13] = {0,1,1,4,4,5,5,7,8,8,11,11,12}
scales[14] = {0,1,1,4,4,6,6,7,8,8,11,11,12}
scales[15] = {0,1,1,3,3,5,5,7,7,10,10,11,12}
scales[16] = {0,1,1,3,3,6,6,7,8,8,11,11,12}
scales[17] = {0,0,2,2,4,5,5,9,9,10,10,11,12}
scales[18] = {0,0,2,2,5,5,7,7,9,9,9,12,12}
scales[19] = {0,0,3,3,3,5,5,8,8,10,10,12,12}
scales[20] = {0,0,3,3,4,4,6,6,8,8,10,10,12}
scales[21] = {0,1,1,3,4,5,5,7,8,8,10,10,12}
scales[22] = {0,1,1,5,5,5,7,7,8,8,8,12,12}
scales[23] = {0,1,1,3,3,7,7,8,8,8,12,12,12}
scales[24] = {0,0,2,2,4,4,6,6,8,8,10,10,12}

-- Scale names for param
scale_names = {}
scale_names[1] = "Chromatic"
scale_names[2] = "Ionian"
scale_names[3] = "Dorian"
scale_names[4] = "Phrygian"
scale_names[5] = "Lydian"
scale_names[6] = "Mixolydian"
scale_names[7] = "Aeolian Minor"
scale_names[8] = "Locrian"
scale_names[9] = "Blues Major"
scale_names[10] = "Blues Minor"
scale_names[11] = "Pentatonic Major"
scale_names[12] = "Pentatonic Minor"
scale_names[13] = "Raga Bhiarav"
scale_names[14] = "Raga Shri"
scale_names[15] = "Raga Rupatavi"
scale_names[16] = "Raga Todi"
scale_names[17] = "Raga Kaafi"
scale_names[18] = "Raga Meg"
scale_names[19] = "Raga Malkauns"
scale_names[20] = "Raga Deepak"
scale_names[21] = "Folkish"
scale_names[22] = "Japanese"
scale_names[23] = "Gamelan"
scale_names[24] = "Whole Tone"

-- Randomly shuffled note indices
local shuffled_note_indices = {}
shuffled_note_indices[1]  = {1,2,3,4,5,6,7,8,9,10,11,12,13}
shuffled_note_indices[2]  = {12,1,10,13,3,9,7,8,5,4,11,6,2}
shuffled_note_indices[3]  = {3,6,13,2,9,12,5,11,1,7,10,8,4}
shuffled_note_indices[4]  = {4,13,3,10,1,5,7,6,12,8,9,11,2}
shuffled_note_indices[5]  = {10,7,1,11,13,9,8,2,12,6,3,4,5}
shuffled_note_indices[6]  = {11,10,4,9,1,6,2,12,5,3,7,13,8}
shuffled_note_indices[7]  = {12,9,11,5,8,7,3,2,13,1,4,10,6}
shuffled_note_indices[8]  = {9,13,3,2,6,11,10,7,1,5,4,8,12}
shuffled_note_indices[9]  = {4,1,2,10,6,9,3,5,12,8,11,7,13}
shuffled_note_indices[10] = {1,7,9,3,10,11,5,8,6,4,2,13,12}
shuffled_note_indices[11] = {13,9,12,10,6,8,1,5,4,2,11,3,7}
shuffled_note_indices[12] = {8,11,1,13,5,4,2,3,10,7,9,12,6}
shuffled_note_indices[13] = {4,12,1,5,13,9,7,2,10,11,8,6,3}
shuffled_note_indices[14] = {1,7,13,11,10,12,6,4,5,2,9,3,8}
shuffled_note_indices[15] = {4,11,1,5,12,7,8,3,2,13,6,10,9}
shuffled_note_indices[16] = {2,10,13,5,6,9,4,7,3,11,12,8,1}

------------------------------------------
-- Module Properties ---------------------
------------------------------------------

local Quantiser = {}

-- Quantiser state
Quantiser.state = {
    scale_name = "Chromatic",
	root_note_name = "C",
    last_note_name = "C",
    last_note_index = 1,
    last_octave_index = 1,
    last_octave_indicator = " "
}

-- Current scale index
Quantiser.currentScaleIndex = 1
-- Current scale table
Quantiser.currentScale = {}
-- Current Scale name
Quantiser.currentScaleName = ""
-- Base Octave
Quantiser.baseOctave = 0
-- Shuffled scale indices
Quantiser.noteScaleShuffle = 1
-- Note scale-rotation
Quantiser.noteScaleRotation = 0
-- Octave scale-rotation
Quantiser.octScaleRotation = 0
-- Preserve base note index flag
Quantiser.noteScalePreserveBaseIndex = 2
-- Note/Octave indices
Quantiser.noteIndicesFx = {1,2,3,4,5,6,7,8,9,10,11,12,13}
Quantiser.octIndicesFx = {1,2,3}

-- Debug mode toggle
Quantiser.debugMode = false

------------------------------------------
-- Add Params ----------------------------
------------------------------------------

function Quantiser.addParams()

    print("Adding Quantiser parameters")

    params:add_group("Bline Quantiser", 7)

    -- Scale-select
    params:add_option("quant_scale", "Scale", scale_names, 1)
    params:set_action(
		"quant_scale",
		function(x)
			Quantiser.changeScale(x)
			--SCREEN_DIRTY = true
		end
	)

	-- Shuffle note-lookup indices
	params:add {
		id = "quant_note_shuffled_indices",
		name = "Note Scale Shuffle",
		type = "number",
		min = 1,
		max = 16,
		default = 1,
    	action = function(x)
			Quantiser.noteScaleShuffle = x
			Quantiser.createIndices()
			--SCREEN_DIRTY = true
		end
	}

    -- Note scale-rotate
	params:add_control (
		"quant_note_scale_rotation",
		"Note Scale Rotate",
		ControlSpec.new(0, 1, 'lin', 0.1, 0)
	)
	params:set_action (
		"quant_note_scale_rotation",
		function(x)
			Quantiser.noteScaleRotation = x * 2
			Quantiser.createIndices()
			--SCREEN_DIRTY = true
		end
	)

	-- Octave scale-rotate
	params:add_control (
		"quant_oct_scale_rotation",
		"Octave Scale Rotate",
		ControlSpec.new(0, 1, 'lin', 0.1, 0)
	)
	params:set_action (
		"quant_oct_scale_rotation",
		function(x)
			Quantiser.octScaleRotation = x * 2
			Quantiser.createIndices()
			--SCREEN_DIRTY = true
		end
	)

	-- Scale preserve root note
	params:add_option(
		"quant_preserve_root",
		"Preserve Root Note",
		{"OFF", "ON"},
		2
	)
	params:set_action(
		"quant_preserve_root",
		function(x)
			Quantiser.noteScalePreserveBaseIndex = x
			Quantiser.createIndices()
			--SCREEN_DIRTY = true
		end
	)

    -- Root-note select
    params:add_option(
		"quant_root",
		"Root Note",
		rootnote_names,
		7
	)
    params:set_action(
		"quant_root",
		function(x)
			Quantiser.state["root_note_name"] = rootnote_names[x]
			--SCREEN_DIRTY = true
		end
	)

    -- Octave-shift
    params:add_option(
		"quant_octave",
		"Octave",
		{"-1", "0", "+1"},
		2
	)
    params:set_action(
		"quant_octave",
		function(x)
			Quantiser.baseOctave = x
			--SCREEN_DIRTY = true
		end
	)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End Quantiser.addParams()

------------------------------------------
-- Change Active Scale
------------------------------------------

function Quantiser.changeScale(index)

    -- Set scale index
    Quantiser.currentScaleIndex = index

    -- Update scale name
    Quantiser.currentScaleName = scale_names[index]

    -- Change active scale table
    Quantiser.currentScale = scales[index]

end -- End Quantiser.changeScale()

------------------------------------------
-- Shuffle Scale Indices -----------------
------------------------------------------

function Quantiser.scaleIndexShuffle()

	-- Return shuffled indices (index 1 is unshuffled)
	return shuffled_note_indices[Quantiser.noteScaleShuffle or 1]

end -- End Quantiser.scaleIndexShuffle()

------------------------------------------
-- Rotate Scale Indices ------------------
------------------------------------------

function Quantiser.scaleIndexRotate(indices, base_index, rotation)

	-- Flatten indices towards base_index, then expand towards inverted indices

	local rotated_indices = {}

	-- Get length of indices array
	local indices_len = 1 + TabUtil.count(indices)

	-- If completion <= 1, flatten all scale indices towards 1
	if (rotation < 1) then
		-- Loop through index vals
		for i, _ in ipairs(indices) do
			-- Lerp indices
			rotated_indices[i] = (indices[i] * (1 - rotation)) + (rotation * base_index)
			-- Round indices
			rotated_indices[i] = NornsUtils.round(rotated_indices[i], 1)
		end
	else -- Else lerp indices towards inverse
		for i, _ in ipairs(indices) do
			local r = rotation - 1 -- 0-1 range
			rotated_indices[i] = (base_index * (1 - r)) + (indices[indices_len - i] * r)
			-- Round indices
			rotated_indices[i] = NornsUtils.round(rotated_indices[i], 1)
		end
	end

	--TabUtil.print(rotated_indices)
	return rotated_indices

end -- End Quantiser.scaleIndexRotate()

------------------------------------------
-- Preserve Base Note Index --------------
------------------------------------------

function Quantiser.preserveBaseNoteIndex(indices)

	-- Force first and last index (root note octaves) if option set
	if (Quantiser.noteScalePreserveBaseIndex == 2) then
		local ind = indices
		ind[1] = 1
		ind[13] = 13
		return ind
	else
		return indices
	end

end -- End

------------------------------------------
-- Create Indices ------------------------
------------------------------------------

-- Create note-lookup indices
function Quantiser.createIndices()

	-- Process note and octave lookup indices
	local note_indices = {}

	-- Get initial indices
	Quantiser.noteIndicesFx = Quantiser.scaleIndexShuffle()

	-- Process note indices through index-rotation
	Quantiser.noteIndicesFx = Quantiser.scaleIndexRotate(
		Quantiser.noteIndicesFx,
		1,
		Quantiser.noteScaleRotation
	)

	-- Re-apply root note indices if option set
	Quantiser.noteIndicesFx = Quantiser.preserveBaseNoteIndex(
		Quantiser.noteIndicesFx
	)

	--Quantiser.noteIndicesFx = note_indices

	-- Process octave indices through index-rotation
	Quantiser.octIndicesFx = Quantiser.scaleIndexRotate(
		{1,2,3},
		2,
		Quantiser.octScaleRotation
	)

end -- End Quantiser.createIndices()

------------------------------------------
-- Apply Scale ---------------------------
------------------------------------------

function Quantiser.applyScale(note, oct)

    -- Get octave (with default value), rounded to nearest integer
	local octave = NornsUtils.clamp(NornsUtils.round(oct or 2, 1), 1, 3)

	-- Set octave indicator string (with default value)
	local octave_indicator = " "
	if (octave < 2) then
		octave_indicator = "-" -- Low octave
	elseif (octave >= 3) then
		octave_indicator = "+" -- High octave
	end

	-- Lookup ctave value in octIndicesFx table
	octave = Quantiser.octIndicesFx[octave]

    -- Get note (with default value), rounded to nearest integer
	-- Clamp to 1 - 12 range (just to be safe)
    local quantised_note = NornsUtils.clamp(NornsUtils.round(note or 1, 1), 1, 13)

    -- Add root-note to note (result may go negative)
    quantised_note = quantised_note + note_transpose_amt[params:get("quant_root")]

    -- Increment/decrement octave
    if (quantised_note > 12) then
        octave = octave + 1
    elseif (quantised_note < 1) then
        octave = octave - 1
    end

    -- Wrap quantised_note to 1-12 range (is this the right thing to do??)
    quantised_note = NornsUtils.wrap(quantised_note, 1, 13)

    -- Lookup note in scale table (result may = 0)
    quantised_note = Quantiser.currentScale[Quantiser.noteIndicesFx[quantised_note]]

    -- Add octaves
	--print("quantised_note: " .. quantised_note .. "  Quantiser.baseOctave: " .. Quantiser.baseOctave .. " octave: " .. octave)

	local final_note = quantised_note + ((octave + Quantiser.baseOctave) * 12)

    -- Update Quantiser state table
    Quantiser.state = {
        scale_name = Quantiser.currentScaleName,
        last_note_name = note_names[quantised_note + 1], -- Add 1 to index because Lua 1-indexed, grr etc.
        last_note_index = final_note,
        last_octave_index = octave,
        last_octave_indicator = octave_indicator
    }

    -- Print debug note info (will produce a Lot out output in Maiden console)
    if (Quantiser.debugMode) then
        print(Quantiser.state.last_octave_string .. Quantiser.state.last_note_name)
    end -- End print debug info

    -- Return final note index + Quantiser state
    return final_note, Quantiser.state

end -- End Quantiser.applyScale()

------------------------------------------
-- Get Quantiser State -------------------
------------------------------------------

function Quantiser.getState()

    return Quantiser.state

end -- End Quantiser.getLastNoteData()

------------------------------------------
-- Init ----------------------------------
------------------------------------------

function Quantiser.init(debug)

    print("Initialising Quantiser module")

    -- Add Quantiser params
    Quantiser.addParams()

    if (debug) then
        Quantiser.debugMode = true
        print("Setting debug mode ON")
    end -- End set debug

	Quantiser.createIndices()

end -- End Quantiser.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return Quantiser
