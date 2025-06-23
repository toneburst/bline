--[[
  Bline UI Module
]]--

local UILib = require "ui"
local NornsUtils = require "lib.util"

-- Splashscreen-playing flag
local splash_playing = true

-- Splashscreen animation frames table
local loading_anim_frames = include("lib/ui/loading_anim")

-- Params data for pages
local page_params = {
	-- Page 1
	{
		-- Param set 1 (Overview)
		{
			-- Param name + label control set 1
			-- Param 1
			{param = "pgen_x", label = "x", longLabel = nil, val = function() return params:get("pgen_x"); end, longVal = nil},
			-- ...param 2
			{param = "pgen_y", label = "y", longLabel = nil, val = function() return params:get("pgen_y"); end, longVal = nil}
		},
		-- Param set 2
		{
			-- Param name + label control set 2
			{param = "pgen_x", label = "x", longLabel = nil, val = function() return params:get("pgen_x"); end, longVal = nil},
			{param = "pgen_y", label = "y", longLabel = nil, val = function() return params:get("pgen_y"); end, longVal = nil}
		},
		pageName = "overview"
	},
	-- Page 2 (Global)
	{
		{
			{param = "pgen_x", label = "x", longLabel = "x-position", val = function() return params:get("pgen_x"); end, longVal = nil},
			{param = "pgen_y", label = "y", longLabel = "y-position", val = function() return params:get("pgen_y"); end, longVal = nil}
		}, {
			{param = "pgen_loop_length", label = "rst", longLabel = "reset bars", val = function()
					local opts = {0.5, 1, 2, 4, 8, 16}
					return opts[params:get("pgen_loop_length")]
				end
			},
			{param = "pgen_pos_jitter", label = "rnd", longLabel = "position jitter", val = function() return params:get("pgen_pos_jitter"); end, longVal = nil}
		},
		pageName = "global"
	},
	-- Page 3 (Notes)
	{
		{
			{param = "quant_note_scale_rotation", label = "rot", longLabel = "note rotate", val = function() return params:get("quant_note_scale_rotation"); end, longVal = nil},
			{param = "ch_note_jitter_scale", label = "rnd", longLabel = "jitter scale", val = function() return params:get("ch_note_jitter_scale"); end, longVal = nil}
		}, {
			{param = "ch_note_length", label = "len", longLabel = "length", val = function() return params:get("ch_note_length"); end, longVal = nil},
			{param = "ch_note_offset", label = "ofs", longLabel = "offset", val = function() return params:get("ch_note_offset"); end, longVal = nil}
		},
		pageName = "note"
	},
	-- Page 4 (Octaves)
	{
		{
			{param = "quant_oct_scale_rotation", label = "rot", longLabel = "octave rotate", val = function() return params:get("quant_oct_scale_rotation"); end, longVal = nil},
			{param = "ch_octave_jitter_scale", label = "rnd", longLabel = "jitter scale", val = function() return params:get("ch_octave_jitter_scale"); end, longVal = nil}
		}, {
			{param = "ch_octave_length", label = "len", longLabel = "length", val = function() return params:get("ch_octave_length"); end, longVal = nil},
			{param = "ch_octave_offset", label = "ofs", longLabel = "offset", val = function() return params:get("ch_octave_offset"); end, longVal = nil}
		},
		pageName = "octave"
	},
	-- Page 5 (Accents)
	{
		{
			{param = "ch_accent_density", label = "den", longLabel = "density", val = function() return params:get("ch_accent_density"); end, longVal = nil},
			{param = "ch_accent_jitter_scale", label = "rnd", longLabel = "jitter scale", val = function() return params:get("ch_accent_jitter_scale"); end, longVal = nil}
		}, {
			{param = "ch_accent_length", label = "len", longLabel = "length", val = function() return params:get("ch_accent_length"); end, longVal = nil},
			{param = "ch_accent_offset", label = "ofs", longLabel = "offset", val = function() return params:get("ch_accent_offset"); end, longVal = nil}
		},
		pageName = "accent"
	},
	-- Page 6 (Slides)
	{
		{
			{param = "ch_slide_density", label = "den", longLabel = "density", val = function() return params:get("ch_slide_density"); end, longVal = nil},
			{param = "ch_slide_jitter_scale", label = "rnd", longLabel = "jitter scale", val = function() return params:get("ch_slide_jitter_scale"); end, longVal = nil}
		}, {
			{param = "ch_slide_length", label = "len", longLabel = "length", val = function() return params:get("ch_slide_length"); end, longVal = nil},
			{param = "ch_slide_offset", label = "ofs", longLabel = "offset", val = function() return params:get("ch_slide_offset"); end, longVal = nil}
		},
		pageName = "slide"
	},
	-- Page 7 (Rests)
	{
		{
			{param = "ch_rest_density", label = "den", longLabel = "density", val = function() return params:get("ch_rest_density"); end, longVal = nil},
			{param = "ch_rest_jitter_scale", label = "rnd", longLabel = "jitter scale", val = function() return params:get("ch_rest_jitter_scale"); end, longVal = nil}
		}, {
			{param = "ch_rest_length", label = "len", longLabel = "length", val = function() return params:get("ch_rest_length"); end, longVal = nil},
			{param = "ch_rest_offset", label = "ofs", longLabel = "offset", val = function() return params:get("ch_rest_offset"); end, longVal = nil}
		},
		pageName = "rest"
	},
	-- Page 8 (Quantiser)
	{
		{
			{param = "quant_scale", label = "scl", longLabel = "scale", val = function() return params:get("quant_scale"); end, longVal = function()
					local opts = {"Chromatic","Ionian","Dorian","Phrygian","Lydian","Mixolydian","Aeolian Minor","Locrian","Blues Major","Blues Minor","Pentatonic Major","Pentatonic Minor","Raga Bhiarav","Raga Shri","Raga Rupatavi","Raga Todi","Raga Kaafi","Raga Meg","Raga Malkauns","Raga Deepak","Folkish","Japanese","Gamelan","Whole Tone"}
					return opts[params:get("quant_scale")]
				end
			},
			{param = "quant_note_shuffled_indices", label = "sfl", longLabel = "shuffle", val = function() return params:get("quant_note_shuffled_indices"); end, longVal = nil}
		}, {
			{param = "quant_root", label = "rt", longLabel = "root note", val = function()
					local opts = {"-F#","-G","-G#","-A","-A#","-B","C","+C#","+D","+D#","+E","+F","+F#"}
					return opts[params:get("quant_root")]
				end,
				longVal = nil
			},
			{param = "quant_octave", label = "oct", longLabel = "octave", val = function()
					local vals = {-1, 0, 1}
					return vals[params:get("quant_octave")]
				end,
				longVal = nil
			}
		},
		pageName = "quantiser"
	}
}

-- Timer clock for modal dialog (not implemented)
--local modal_timer = nil

local UI = {}

-- State tables
UI.channelStates = {}
UI.stepState = nil

-- Page/Control-set indices and data for current page
UI.pageIndex = 1
UI.controlIndex = 1
UI.currentParams = page_params[1]

-- Positions
UI.pageDrawX = 80
UI.pageDrawY = 12

-- Page Background image buffer
UI.background = screen.load_png("/home/we/dust/code/bline/lib/ui/png/ui-bg.png")
UI.backgroundXOffset = 0

-- Flags
UI.doneSplash = false
UI.debugMode = false
UI.displayMode = 1 		-- 1 = normal, 2 = inverted

--[[

UI Function Arguments::::::

channel_states {
	"notes" : {
		"pattern_length" : int 1-16
		"pattern_offset" : int 1-16
		"pattern_xy_freeze" : bool
		"pattern" : array 16 vals various ranges
		"raw_pattern" : array 16 vals, 0-1 range
		"step_index" : int 1 - 16
	},
	"octaves" : {data as above},
	"accents" : {etc.},
	"slides" : {etc.},
	"rests" : {etc.}
}

current_step_state {
	"last_note" : float 1.0 - 12.0 note index
	"last_accent" : bool accent on/off
	"slide" : bool slide on/off
	"rest" : bool rest on/off
	"scale_name" : string scale name
	"last_note_name" : string note name
	"last_note_index" : float note index
	"last_octave_index" : float 0.0 - 4.0 (?) octave index
	"last_octave_indicator" : string octave-indicator ("-" / " " / "+")
}

]]--

-- https://monome.org/docs/norns/api/modules/screen.html

------------------------------------------
-- Get screen level ----------------------
------------------------------------------

local function getScreenLevel(index)
	if (UI.displayMode == 1) then
		-- Standard mode
		return index
	else
		-- Inverted mode
		return 15 - index
	end
end -- End getScreenLevel()

------------------------------------------
-- Draw Page Background ------------------
------------------------------------------

local function drawPageBG()

	-- Draw background image
	-- Background elements now part of background image
	if (UI.pageIndex == 1) then
		-- Draw page 1 background (vertical offset 0px)
		-- display_image_region(image, left, top, width, height, x, y)
		screen.display_image_region(UI.background, UI.backgroundXOffset, 0, 128, 64, 0, 0)
	else
		-- Draw other page background	
		if (UI.controlIndex == 1) then
			-- Top row params selected (vertical offset 64px)
			screen.display_image_region(UI.background, UI.backgroundXOffset, 64, 128, 64, 0, 0)
		else
			-- Bottom row params selected (vertical offset 128px)
			screen.display_image_region(UI.background, UI.backgroundXOffset, 128, 128, 64, 0, 0)
		end
	end

end -- End drawPageBG()

------------------------------------------
-- Draw BPM ------------------------------
------------------------------------------

local function drawBPM()

	screen.move(125,6)
	screen.level(getScreenLevel(0))
	screen.text_right(params:get("clock_tempo") .. "bpm")
	screen.fill()

end -- End drawBPM()

------------------------------------------
-- Draw Top-Bar Graphics -----------------
------------------------------------------

local function drawTitleBar()

	-- Draw BPM (other top-bar items now part of background image)
	drawBPM()

end -- End drawTitleBar()

------------------------------------------
-- Draw XY Position Crosshairs -----------
------------------------------------------

local function drawCrossHairs(draw_x, draw_y, x_pos, y_pos)

	local px = math.floor(math.min(x_pos, 3.8) * 10)
	local py = math.floor(math.min(y_pos, 3.8) * 10) + 3

	-- Draw crosshairs using "+" character
	screen.level(getScreenLevel(15))
	screen.move(draw_x + px, draw_y + py)
	screen.font_face(1)
	screen.font_size(8)
	screen.text_center("+")
	screen.fill()

end -- End drawCrossHair(x_pos, y_pos)

------------------------------------------
-- Draw Current Note Data ----------------
------------------------------------------

local function drawNoteInfo(note_data, draw_x, draw_y)

	screen.move(draw_x, draw_y)
	screen.level(getScreenLevel(10))
	screen.font_face(1)
	screen.font_size(8)
	screen.text(note_data["last_octave_indicator"] .. note_data["last_note_name"])
	screen.fill()

	-- Add accent / slide / rest indicators
	-- We only need to draw text for active steps, as inactive indicators are now part of the background image

	-- Add Accent indicator
	if(note_data["accent"]) then
		screen.move(draw_x + 18, draw_y)
		screen.level(getScreenLevel(15))
		screen.text("a")
		screen.fill()
	end

	-- Add Slide indicator
	if(note_data["slide"]) then
		screen.move(draw_x + 28, draw_y)
		screen.level(getScreenLevel(15))
		screen.text("s")
		screen.fill()
	end

	-- Add Rest indicator
	if(note_data["rest"]) then
		screen.move(draw_x + 38, draw_y)
		screen.level(getScreenLevel(15))
		screen.text("r")
		screen.fill()
	end

end -- End drawNoteInfo(note_data, draw_x, draw_y)

------------------------------------------
-- Draw Page Title -----------------------
------------------------------------------

local function drawPageTitle(str)

	screen.level(getScreenLevel(10))
	screen.font_face(1)
	screen.font_size(8)
	screen.text_rotate (123, 12, str, 90)
	screen.fill()

end -- End drawPageTitle(str)

------------------------------------------
-- Draw Page -----------------------------
------------------------------------------

-- Draw all pages EXCEPT page 1
local function drawPage(draw_x, draw_y)

	local top_text_level, bottom_text_level

	drawPageTitle(UI.currentParams["pageName"])

	-- Set font params
	screen.font_face(1)
	screen.font_size(8)

	-- Set levels
	if (UI.controlIndex == 1) then
		top_text_level = 15
		bottom_text_level = 7
	else
		top_text_level = 7
		bottom_text_level = 15
	end

	-- Draw top row params

	screen.level(getScreenLevel(top_text_level))

	screen.move(draw_x + 9, draw_y + 6)
	screen.text_center(UI.currentParams[1][1]["label"])
	screen.fill()

	screen.move(draw_x + 9, draw_y + 16)
	screen.text_center(UI.currentParams[1][1].val())
	screen.fill()

	screen.move(draw_x + 29, draw_y + 6)
	screen.text_center(UI.currentParams[1][2]["label"])
	screen.fill()

	screen.move(draw_x + 29, draw_y + 16)
	screen.text_center(UI.currentParams[1][2].val())
	screen.fill()

	-- Draw bottom row params

	screen.level(getScreenLevel(bottom_text_level))

	screen.move(draw_x + 9, draw_y + 27)
	screen.text_center(UI.currentParams[2][1]["label"])
	screen.fill()

	screen.move(draw_x + 9, draw_y + 37)
	screen.text_center(UI.currentParams[2][1].val())
	screen.fill()

	screen.move(draw_x + 29, draw_y + 27)
	screen.text_center(UI.currentParams[2][2]["label"])
	screen.fill()

	screen.move(draw_x + 29, draw_y + 37)
	screen.text_center(UI.currentParams[2][2].val())
	screen.fill()

end -- End drawPage(draw_x, draw_y)

------------------------------------------
-- Custom bar-graph drawing function -----
------------------------------------------

local function drawPattern(pattern_data, label, bar_width, y_pos, pre_scale, pre_offset, type)

	--local pattern_data = UI.channelStates[channel]
	local pattern = pattern_data["pattern"]
	local step_index = pattern_data["step_index"]
	local pattern_index_offset = pattern_data["pattern_offset"]
	local pattern_length = pattern_data["pattern_length"]
	local pattern_frozen = pattern_data["pattern_xy_freeze"]

	-- Bar dimensions
	local bar_width = bar_width
	local bar_spacing = 1

	-- Bar positioning
	local base_x = 0
	local base_y = 22
	local label_x = base_x + 2
	local label_y = base_y + y_pos - 1
	local graph_x = base_x + 4
	local graph_y = base_y + y_pos
	local bar_x_incr = bar_width + bar_spacing

	-- Bar shades
	local bar_body_dim = 1
	local bar_body = 3
	local bar_body_highlight = 5

	local bar_top_dim = 3
	local bar_top = 6
	local bar_top_highlight = 15

	-- Draw highlighted label if this is first step of pattern (non-hightlighted labels are now part of background image)
	if((step_index - pattern_index_offset) == 1) then
		screen.move(label_x, label_y)
		screen.font_face(1)
		screen.font_size(8)
		screen.level(getScreenLevel(15))
		screen.text_center(label)
		screen.fill()
	end

	-- Draw pattern
	screen.line_width(bar_width)

	-- Loop through pattern steps
	for i, _ in ipairs(pattern) do

		-- Get value
		-- Offset value lookup index based on channel offset (with wrapping)
		-- This is to give visual feedback when pattern offsets are changed.
		local v = pattern[NornsUtils.wrap(i + pattern_index_offset, 1, 16)]

		-- Convert bool to int if pattern type is "bool"
		if (type == "bool") then
			v = (v and 1 or 0)
		end

		-- Pre-scale/offset + round step value
		v = NornsUtils.round(v * pre_scale + pre_offset)

		local x = graph_x + (bar_x_incr * i)

		-- Bar and top levels
		local body = bar_body
		local top = bar_top

		-- Highlight current step bar
		if((NornsUtils.wrap(step_index - pattern_index_offset, 1, 16)) == i) then
			top = bar_top_highlight
			body = bar_body_highlight
		elseif(i > pattern_length) then
			-- Dim steps beyond pattern length
			top = bar_top_dim
			body = bar_body_dim
		end

		-- Draw bar top
		screen.level(getScreenLevel(top))
		screen.move(x, graph_y)
		screen.line_rel(0, -(v + 1))
		screen.close()
		screen.stroke()
		screen.fill()

		-- Draw bar body
		screen.level(body)
		screen.move(x, graph_y)
		screen.line_rel(0, -v)
		screen.close()
		screen.stroke()
		screen.fill()

	end

	-- Draw freeze lock if lock enabled (disabled lock graphic is now part of background image, so no need to draw it again)
	if(pattern_frozen == 1) then
		screen.display_png("/home/we/dust/code/bline/lib/ui/png/padlock-bright.png", 71, graph_y - 8)
	end

end -- End drawPattern(pattern_data, label, bar_width, y_pos, pre_scale, pre_offset, type)

------------------------------------------
-- Draw XY Page (page 1) -----------------
------------------------------------------

local function drawPageXY(draw_x, draw_y, x_pos, y_pos)

	local x = x_pos
	local y = 4 - y_pos

	local cell_x = math.min(math.floor(x), 3) * 10
	local cell_y = math.min(math.floor(y), 3) * 10

	-- Draw current cell rect
	-- We no longer need to draw the other background cell rects, as they are part of the background image
	screen.level(getScreenLevel(4))
	screen.rect(cell_x + draw_x, cell_y + draw_y, 9, 9)
	screen.close()
	screen.fill()

	-- Draw XY position
	drawCrossHairs(draw_x, draw_y, x, y)

	-- Screen title
	drawPageTitle(UI.currentParams["pageName"])

end

------------------------------------------
-- Play Splash/Loading Animation ---------
------------------------------------------

function UI.playSplash()

	-- Loop through animation frames
	for i, path in ipairs(loading_anim_frames) do
		-- Display png
		screen.display_png(path, 0, 0)
		screen.update()
		-- Pause 1/12 second
		clock.sleep(1 / 12)
    end

	splash_playing = false

end -- End UI.playSplash()

------------------------------------------
-- Set UI Mode ---------------------------
------------------------------------------

function UI.setUIMode(mode)

	-- UI mode (normal/inverted) select
	UI.displayMode = mode

	-- Set background image X offset based on mode
	if (mode == 1) then
		-- Set background image X offset to 0 (normal mode)
		UI.backgroundXOffset = 0
	else
		-- Set background image X offset to 128 (inverted mode)
		UI.backgroundXOffset = 128
	end

end -- End UI.setUIMode(mode)

------------------------------------------
-- Redraw Function -----------------------
------------------------------------------

function UI.redraw(channel_states, step_state)

	-- Play splash animation if flag set
	if (splash_playing == true) then
		UI.playSplash()

	else
		-- Else display UI

		UI.channelStates = channel_states
		UI.stepState = step_state

		-- Disable anti-aliasing
	    screen.aa(0)

		-- Clear screen
		screen.clear()

		-- Draw page background
		drawPageBG()

		-- Draw title bar
		drawTitleBar()

		-- Draw Notes channel graph
		-- Args: (channel, label, bar_width, y_pos, pre_scale, pre_offset, type)
		drawPattern(UI.channelStates["notes"],   "n", 3,  0, 1,  0, "val" )
		drawPattern(UI.channelStates["octaves"], "o", 3, 11, 2, -1, "val" )
		drawPattern(UI.channelStates["accents"], "a", 3, 21, 6,  1, "bool")
		drawPattern(UI.channelStates["slides"],  "s", 3, 31, 6,  1, "bool")
		drawPattern(UI.channelStates["rests"],   "r", 3, 41, 6,  1, "bool")

		-- Draw Pages
		if (UI.pageIndex == 1) then
			-- Draw XY page (page 1)
			drawPageXY(UI.pageDrawX, UI.pageDrawY,
				params:get(page_params[1][1][1]["param"]),
				params:get(page_params[1][1][2]["param"])
			)
		else
			-- Draw other pages
			drawPage(UI.pageDrawX, UI.pageDrawY)
		end

		-- Draw note info
		if (UI.stepState ~= nil) then
			drawNoteInfo(UI.stepState, 79, 62)
		end

	end -- End if (splash_playing == true)

	
	screen.update()

end -- End UI.redraw()

------------------------------------------
-- Handle Encoders -----------------------
------------------------------------------

function UI.handleEncoders(n, delta)

	-- Change page on encoder 1
	if (n == 1) then
		-- Delta page index
		UI.pageIndex = NornsUtils.clamp(UI.pageIndex + delta, 1, 8)
		-- Reset control-set index
		UI.controlIndex = 1
		-- Set current page param data
		UI.currentParams = page_params[UI.pageIndex]
	elseif (n == 2) then
		-- Encoder 2
		params:delta(UI.currentParams[UI.controlIndex][1]["param"], delta)
	elseif (n == 3) then
		-- Encoder 3
		params:delta(UI.currentParams[UI.controlIndex][2]["param"], delta)
	elseif (n == 4) then
		-- Encoder 4
		-- Not implemented
	end

end -- End UI.handleEncoders(n, delta)

------------------------------------------
-- Handle Buttons ------------------------
------------------------------------------

function UI.handleButtons(i)
	if (i == 2) then
		-- Toggle 1, 2
		-- Source: https://forums.cockos.com/showthread.php?t=254657
		UI.controlIndex = UI.controlIndex == 2 and 1 or 2
	end

end -- End UI.handleButtons(i)

------------------------------------------
-- Init Function -------------------------
------------------------------------------

function UI.init(debug)

	print("Initialising UI module")

	-- Init background image buffer
	--UI.background = screen.load_png("/home/we/dust/code/bline/lib/ui/png/ui-bg.png")
	if (debug == true) then
		UI.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

end -- End UI.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return UI
