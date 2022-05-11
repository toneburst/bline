--[[
  Bline UI Module
]]--

local TabUtil = require "lib.tabutil"
local UILib = require "ui"
local NornsUtils = require "lib.util"
local Graph = require "lib.graph"

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
					local opts = {0.5, 1, 2, 4, 6, 16}
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

local UI = {}

-- State tables
UI.channelStates = {}
UI.stepState = nil

-- Page/Control-set indices and data for current page
UI.pageIndex = 1
UI.controlIndex = 1
UI.currentParams = page_params[1]

-- Positions
UI.pageDrawX = 79
UI.pageDrawY = 12

-- Flags
UI.doneSplash = false
UI.debugMode = false

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
-- Draw Top-Bar Graphics -----------------
------------------------------------------

local function drawTitleBar()

	-- Draw bar
	screen.level(10)
	screen.line_width(8)
	screen.move(0,3)
	screen.line(127,3)
	screen.close()
    screen.stroke()
	screen.fill()

	screen.font_face(1)
	screen.font_size(8)

	-- Draw Title
	screen.level(0)
	screen.move(2,6)
	screen.text("bLINE")
	screen.fill()

	-- Draw bpm
	screen.move(125,6)
	screen.text_right(params:get("clock_tempo") .. "bpm")
	screen.fill()

end -- End drawTitleBar()

------------------------------------------
-- Draw XY Position Crosshairs -----------
------------------------------------------

local function drawCrossHairs(draw_x, draw_y, x_pos, y_pos)

	local px = math.floor(math.min(x_pos, 3.8) * 10)
	local py = math.floor(math.min(y_pos, 3.8) * 10) + 3

	-- Draw crosshairs using "+" character
	screen.level(15)
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
	screen.level(10)
	screen.font_face(1)
	screen.font_size(8)
	screen.text(note_data["last_octave_indicator"] .. note_data["last_note_name"])
	screen.fill()

	-- Add Accent
	screen.move(draw_x + 18, draw_y)
	screen.level(3)
	if(note_data["accent"]) then
		screen.level(15)
	end
	screen.text("a")
	screen.fill()

	-- Add Slide
	screen.move(draw_x + 28, draw_y)
	screen.level(3)
	if(note_data["slide"]) then
		screen.level(15)
	end
	screen.text("s")
	screen.fill()

	-- Add Rest
	screen.move(draw_x + 38, draw_y)
	screen.level(3)
	if(note_data["rest"]) then
		screen.level(15)
	end
	screen.text("r")
	screen.fill()

end -- End drawNoteInfo(note_data, draw_x, draw_y)

------------------------------------------
-- Draw Page Title -----------------------
------------------------------------------

local function drawPageTitle(str)

	screen.level(10)
	screen.font_face(1)
	screen.font_size(8)
	screen.text_rotate (123, 12, str, 90)
	screen.fill()

end -- End drawPageTitle(str)

------------------------------------------
-- Draw Param Modal ----------------------
------------------------------------------

local function drawParamModal()

end -- End drawParamModal()

------------------------------------------
-- Draw Page Frame -----------------------
------------------------------------------

local function drawPageFrame(draw_x, draw_y)

	-- Draw page frame
	screen.level(6)
	screen.line_width(1)
	-- screen.rect (x, y, w, h)
	screen.rect(draw_x - 1, draw_y - 1, 42, 42)
	screen.stroke()

end -- End drawPageFrame()

------------------------------------------
-- Draw Page -----------------------------
------------------------------------------

-- Draw all pages except first
local function drawPage(draw_x, draw_y)

	local top_bg_level, top_text_level, bottom_bg_level, bottom_text_level

	-- Draw page frame
	drawPageFrame(draw_x, draw_y)

	drawPageTitle(UI.currentParams["pageName"])

	screen.font_face(1)
	screen.font_size(8)

	-- Draw top row background ---------------

	-- Set background colour top row
	if (UI.controlIndex == 1) then
		top_bg_level = 4
		top_text_level = 15
		bottom_bg_level = 2
		bottom_text_level = 7
	else
		top_bg_level = 2
		top_text_level = 7
		bottom_bg_level = 4
		bottom_text_level = 15
	end

	screen.level(top_bg_level)

	screen.rect(draw_x, draw_y, 19, 19)
	screen.close()
	screen.fill()

	screen.rect(draw_x + 20, draw_y, 19, 19)
	screen.close()
	screen.fill()

	screen.level(top_text_level)

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

	-- Draw bottom row background --------

	screen.level(bottom_bg_level)

	screen.rect(draw_x, draw_y + 20, 19, 19)
	screen.close()
	screen.fill()

	screen.rect(draw_x + 20, draw_y + 20, 19, 19)
	screen.close()
	screen.fill()

	screen.level(bottom_text_level)

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
	local bar_body = 3
	local bar_body_highlight = 5
	local bar_top = 6
	local bar_top_highlight = 15

	-- Draw label
	screen.move(label_x, label_y)
	screen.font_face(1)
	screen.font_size(8)

	-- Highlight label on first step of pattern
	if((step_index - pattern_index_offset) == 1) then
		screen.level(15)
	else
		screen.level(3)
	end

	screen.text_center(label)
	screen.fill()

	-- Draw pattern
	screen.line_width(bar_width)

	for i, _ in ipairs(pattern) do

		-- Get value
		-- Offset value lookup index based on channel offset (with wrapping)
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
		if((step_index - pattern_index_offset) == i) then
			top = bar_top_highlight
			body = bar_body_highlight
		end

		-- Draw bar top
		screen.level(top)
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

end -- End drawPattern(pattern_data, label, bar_width, y_pos, pre_scale, pre_offset, type)

------------------------------------------
-- XY Page -------------------------------
------------------------------------------

local function drawPageXY(draw_x, draw_y, x_pos, y_pos)

	local cell_x = math.min(math.floor(x_pos), 3) * 10
	local cell_y = math.min(math.floor(y_pos), 3) * 10

	-- Draw page frame
	drawPageFrame(draw_x, draw_y)

	screen.level(2)

	-- Draw background cell rects
	for row = 0, 30, 10
	do
		for col = 0, 30, 10
		do
			screen.rect(draw_x + col, draw_y + row, 9, 9)
			screen.close()
			screen.fill()
		end
	end

	-- Draw current cell rect
	screen.level(4)
	screen.rect(cell_x + draw_x, cell_y + draw_y, 9, 9)
	screen.close()
	screen.fill()

	-- Draw XY position
	drawCrossHairs(draw_x, draw_y, x_pos, y_pos)

	-- Screen title
	drawPageTitle(UI.currentParams["pageName"])

end

------------------------------------------
-- Redraw Function -----------------------
------------------------------------------

function UI.redraw(channel_states, step_state)

	UI.channelStates = channel_states
	UI.stepState = step_state

	-- Enable anti-aliasing
    screen.aa(0)
	screen.clear()

	-- Draw titlebar
	drawTitleBar()

	-- Draw Notes channel graph
	-- Args: (channel, label, bar_width, y_pos, pre_scale, pre_offset, type)
	drawPattern(UI.channelStates["notes"], "n", 3, 0, 1, 0, "val")
	drawPattern(UI.channelStates["octaves"], "o", 3, 11, 2, -1, "val")
	drawPattern(UI.channelStates["accents"], "a", 3, 21, 6, 1, "bool")
	drawPattern(UI.channelStates["slides"], "s", 3, 31, 6, 1, "bool")
	drawPattern(UI.channelStates["rests"], "r", 3, 41, 6, 1, "bool")

	-- Draw Pages
	if (UI.pageIndex == 1) then
		drawPageXY(UI.pageDrawX, UI.pageDrawY,
			params:get(page_params[1][1][1]["param"]),
			params:get(page_params[1][1][2]["param"])
		)
	else
		drawPage(UI.pageDrawX, UI.pageDrawY)
	end

	-- Draw note info
	if (UI.stepState ~= nil) then
		drawNoteInfo(UI.stepState, 79, 62)
	end

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
		-- do nothing
	end

end -- End UI.handleEncoders(n, delta)

------------------------------------------
-- Handle Buttons ------------------------
------------------------------------------

function UI.handleButtons(i)

	if (i == 3) then
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

	if (debug == true) then
		UI.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

end -- End UI.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return UI
