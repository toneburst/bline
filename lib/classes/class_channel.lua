--[[
Bline Pattern Channel Class
]]--

-- OOP implementation of channel class.
-- Handles a single channel of pattern generation and playback.
--
-- Lines post:
-- https://llllllll.co/t/lua-oop-hair-tearing/53637
--
-- Coding style guide (apply!)
-- https://flamendless.github.io/lua-coding-style-guide/

local ControlSpec = require "controlspec"
local NornsUtils = require "lib.util"
local TabUtil = require "lib.tabutil"

-- Require node data module to prevent it being loaded multiple times
local pattern_map = require(_path.code .. "bline/lib/data/dat_pattern_data")

local Channel = {}

function Channel:new(o)

    -- Setup metatable
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Declare instance properties
	o.channelType = nil	-- Channel output type (boolean/number)
	o.baseChannelIndex = 1
	o.channelIndex = o.baseChannelIndex
    o.channelName = ""

	o.paramGroupCount = 4 -- Parameter-count
	o.paramPrefix = ""
    o.param1Label = nil
    o.param1ID = ""
    o.param1Curve = 1.0
    o.param1Value = 1.0

	o.patternLength = 16
	o.patternOffset = 0
	o.posX = 0
	o.posY = 0
	o.freezePosYX = 0
	o.posXFrozen = 0
	o.posYFrozen = 0
	o.jitterVals = {}
	o.jitterScale = 0
    o.firstVal = nil	-- Forced value for first step in bar
	o.outputScale = 1	-- Step value scale (for number output type)
	o.outputOffset = 0	-- Step value offset (for number output type)

	o.masterOffset = 0
	o.masterCounter = 1
	o.barCounter = 1
	o.currentStep = 1

	o.nodes = {}
	o.pattern = {}
	o.rawPattern = {}
	o.randomPattern = {}

	-- Pattern State to return to UI.
	-- TODO: rewrite so state table items are used by functions to avoid duplication
	o.channelState = {
		pattern_length = 16,
		pattern_offset = 0,
		pattern_xy_freeze = 0,
		pattern = {},
		raw_pattern = {},
		step_index = 1
	}

	--o.run = false
    o.debugMode = false

    return o

end -- End Channel:new()

-----------------------------------------
-- Init ---------------------------------
-----------------------------------------

function Channel:init(
	ch_index,
	ch_name,
	param_label,
	param_curve,
	ch_type,
	first_val,
	output_scale,
	output_offset,
	debug)

    if (debug) then
        self.debugMode = true
        print("Setting debug mode ON")
    end -- End set debug mode

    -- Set object properties ----------------

	self.baseChannelIndex = ch_index
	self.channelIndex = self.baseChannelIndex
    self.channelName = ch_name
    self.paramPrefix = "ch_" .. string.lower(ch_name) .. "_"
    self.param1Curve = param_curve or 1
    self.channelType = ch_type
    self.firstVal = first_val
	self.jitterVals = jitter_vals
	self.outputScale = output_scale
	self.outputOffset = output_offset
    self.debugMode = debug

    print("Initialising " .. self.channelName .. " channel")

    -- Add params ---------------------------

    -- Add channel-specific params if specified
	if (param_label ~= nil) then
		-- Group for all params
		params:add_group("Bline " .. self.channelName, self.paramGroupCount + 1)
		-- Param names
		self.param1ID = self.paramPrefix .. string.lower(param_label)
	    self.param1Label = self.channelName .. " " .. param_label
		-- Add params
		self:addParams(param_label)
	else
		params:add_group("Bline " .. self.channelName, self.paramGroupCount)
	end

    -- Add shared params (same for all instances)
    self:addCommonParams()

    -- Calculate pattern --------------------

    --self:calculatePattern(self.jitterVals)

end -- End Channel:init(ch)

-----------------------------------------
-- Add Params ---------------------------
-----------------------------------------

-- Channel-specific params (override this method per-instance if required)
function Channel:addParams()

    print("Adding channel-specific parameters")

    -- Reusable local vars to hold param id and label
    local id, label = nil

    -- Param 1
    id = self.param1ID
    label = self.param1Label

	-- Add param
    params:add_control(
		id,
		label,
		ControlSpec.new(0, 1, 'lin', 0.01, 0)
	)
    params:set_action(
		id,
		function(x)
			self.param1Value = x
			self:calculatePattern(nil, nil, nil)
			SCREEN_DIRTY = true
		end
	)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End Channel:addParams()

-----------------------------------------
-- Add Common Params --------------------
-----------------------------------------

-- Add commmon params (same for all instances)
function Channel:addCommonParams()

    print("Adding common channel parameters")

    -- Reusable local vars to hold param id and label
    local id, label = nil

    -- Add pattern-Length Param
    id = self.paramPrefix .. "length"
    label = self.channelName .. " Length"
	params:add {
		id = id,
		name = label,
		type = "number",
		min = 1,
		max = 16,
		default = 16,
		action = function(x)
			self.channelState["pattern_length"] = x
			self.patternLength = x
		end
	}

    -- Add pattern-offset Param
    id = self.paramPrefix .. "offset"
    label = self.channelName .. " Offset"
	params:add {
		id = id,
		name = label,
		type = "number",
		min = 0,
		max = 15,
		default = 0,
		action = function(x)
			self.patternOffset = x
			-- Add master offset to value stored in pattern state table
			self.channelState["pattern_offset"] = self.patternOffset + self.masterOffset
		end
	}

	-- Add position jitter scale param
    id = self.paramPrefix .. "jitter_scale"
    label = self.channelName .. " Jitter Scale"
    params:add_control(
		id,
		label,
		ControlSpec.new(0, 1.0, 'lin', 0.1, 1)
	)
    params:set_action(
		id,
		function(x)
			self.jitterScale = x
			self:calculatePattern(self.posX, self.posY, self.jitterVals)
			SCREEN_DIRTY = true
		end
	)

	-- Add XY freeze param
	id = self.paramPrefix .. "freeze_pos"
    label = self.channelName .. " Freeze Position"
    params:add_binary(
		id,
		label,
		"toggle"
	)
    params:set_action(
		id,
		function(x)
			self.freezePosYX  = x
			self.posXFrozen = self.posX
			self.posYFrozen = self.posY
			self.channelState["pattern_xy_freeze"] = self.freezePosYX
			SCREEN_DIRTY = true
		end
	)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End Channel:addParams()

-----------------------------------------
-- Update Jitter Array ------------------
-----------------------------------------

-- Update position jitter values table
function Channel:updateJitterVals(vals)

	self.jitterVals = vals

end -- End Channel:updateJitterVals(jitter_vals)

-----------------------------------------
-- Set Master Offset --------------------
-----------------------------------------

function Channel:updateMasterOffset(offset)

	self.masterOffset = offset

	-- Update channel state table
	self.channelState["pattern_offset"] = self.patternOffset + self.masterOffset

end -- End Channel:updateMasterOffset(offset)

-----------------------------------------
-- Update Step-Counters -----------------
-----------------------------------------

-- Update channel step and bar counters
function Channel:updateCounters(m_counter)

	-- Ensure counter is set to 1 if initially unset (ie nil)
    local counter = m_counter or 1

	-- Counts 1-16 over one bar irrespective of step-counter wrap/offset
	-- Used to apply fixed value to first step in bar
	if (counter == 1) then
		self.barCounter = 1
	else
		self.barCounter = NornsUtils.wrap(self.barCounter + 1, 1, 16)
	end

    -- Update step counter, with offset and wrapping
	self.currentStep = NornsUtils.wrap(NornsUtils.wrap(counter, 1, self.patternLength) + self.patternOffset + self.masterOffset, 1, 16)

	-- Update channel state table
	self.channelState["step_index"] = self.currentStep

	--print(self.channelState["step_index"])

end -- End Channel:updateCounters()

-----------------------------------------
-- Update Channel Index -----------------
-----------------------------------------

-- Update channel index. Determines which channel to look up in node data table
function Channel:updateChannelIndex(offset)

	-- Offset channel index with wrapping
	self.channelIndex = NornsUtils.wrap(self.baseChannelIndex + offset, 1, 6)
	-- Update channel state table
	self.channelState["channel_index"] = self.channelIndex

	-- Update pattern
	self:calculatePattern()

end -- End Channel:updateChannelIndex(offset)

-----------------------------------------
-- Calculate Channel Pattern ------------
-----------------------------------------

-- Calculate 16-step pattern by bilinear interpolation (MI Grids-style)
-- With position jitter/chaos
function Channel:calculatePattern()

	-- Position jitter values
	local j_amt = (params:get("pgen_pos_jitter")^2) * (self.jitterScale^2)

	-- Local vars for position X and Y
	local pos_x, pos_y = 0

	-- Set position to pgen params or frozen values if option set
	if (self.freezePosYX == 1) then
		-- Set X and Y to frozen values
		pos_x = self.posXFrozen
		pos_y = self.posYFrozen
	else
		-- Set X and Y to clamped param values
		-- Clamp to just below 5 so node index never goes out of range
		-- (but values should get rounded up to last node values, anyway)
		pos_x = (NornsUtils.clamp(params:get("pgen_x"), 0, 3.999) + 1) -- Add 1 because Lua arrays 1-indexed (grrr...)
	    pos_y = (NornsUtils.clamp(params:get("pgen_y"), 0, 3.999) + 1)
		self.posX = pos_x
	    self.posY = pos_y
	end

	-- Update pattern state table
	self.channelState["pos_x"] = pos_x
	self.channelState["pos_y"] = pos_y

	--print("Updating pattern for " .. self.channelName .. " channel")

    -- Loop through steps
    for step = 1, 16, 1
    do
		-- Add jitter from array, wrapping result
		local j_x = NornsUtils.wrap(pos_x + (self.jitterVals[step]["x"] * j_amt), 1, 4.999)
		local j_y = NornsUtils.wrap(pos_y + (self.jitterVals[step]["y"] * j_amt), 1, 4.999)
		-- Seems that wrap() doesn't always keep values within range, so clamping, too
		j_x = NornsUtils.clamp(j_x, 1, 4.999)
		j_y = NornsUtils.clamp(j_y, 1, 4.999)

        -- Row and column node indices and fractional (interpolaton) values
        local col = math.floor(j_x)
        local col_frac = j_x - col
        local row = math.floor(j_y)
        local row_frac = j_y - row
        -- Get data at 4 corners
        -- a b
        -- c d
		local a = pattern_map.pattern_nodes[row][col][self.channelIndex][step]
		local b = pattern_map.pattern_nodes[row][col + 1][self.channelIndex][step]
		local c = pattern_map.pattern_nodes[row + 1][col][self.channelIndex][step]
		local d = pattern_map.pattern_nodes[row + 1][col + 1][self.channelIndex][step]
        -- Bilinear interpolation
        local a_b = (a * (1.0 - col_frac)) + (b * col_frac)
        local c_d = (c * (1.0 - col_frac)) + (d * col_frac)
        local val = (a_b * (1.0 - row_frac)) + (c_d * row_frac)
        -- Set pattern step value, pre-processing through processStepVals() method
        self.pattern[step] = self:processStepVals(val, step)
		self.channelState["pattern"][step] = self.pattern[step]
		-- Set raw pattern values (might be handy in UI somehow)
		self.rawPattern[step] = val
		self.channelState["raw_pattern"][step] = val

	end -- End loop

    return self.pattern

end -- End Channel:getRawPattern()

-----------------------------------------
-- Process Step Values ------------------
-----------------------------------------

-- Process step values before writing to pattern table
-- Override this method per-instance if required (ie for Note/Octave channels)
function Channel:processStepVals(val, step)

    -- Apply response-curve to threshold param value
    local threshold = self.param1Value^self.param1Curve
	-- Apply scale and offset to looked-up value
	local scaled_val = (val * self.outputScale) + self.outputOffset

    -- Return boolean if self.valType is "bool"
    if (self.channelType == "bool") then
		-- Boolean types compare scaled and offset value to threshold
		-- and return true or false
		return scaled_val < threshold
    else
		-- number type returns scaled and offset value
		return scaled_val
    end -- End channel type

end -- End Channel:processStepVals(val)

-----------------------------------------
-- Get Pattern --------------------------
-----------------------------------------

-- Return channel state object
-- This should be all the data needed to draw UI for this pattern
-- Called at screen refresh rate
function Channel:getState()

	-- Return Pattern State table
    -- state {
	--	channel_index,
    --	pos_x,
    --	pos_y,
	-- 	pattern_xy_freeze,
    --	pattern,
	--	raw_pattern,
    --	step_index
    -- }

	return self.channelState

end -- End Channel:getPattern()

-----------------------------------------
-- Do Step ------------------------------
-----------------------------------------

-- 'tick' counter and return step value
function Channel:tick(m_counter)

    --print(self.channelName .. " object tick " .. m_counter)

	local step_val

	-- Update local step-counter for next step
	self:updateCounters(m_counter)

    -- Force value of first step in bar if first_val set non-nil at channel init
    if (self.barCounter == 1) and (self.firstVal ~= nil) then
        step_val = self.firstVal
    else
        step_val = self.pattern[self.currentStep]
    end -- End if (self.barCounter == 1) and (self.firstVal ~= nil)

    -- Return step value
    return step_val

end -- End Channel:tick()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return Channel
