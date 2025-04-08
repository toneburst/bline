

local deviceBlineSynth = {}

function deviceBlineSynth.noteOn(note, velocity)
	print("Note On " .. "Note: " .. note)
end

function deviceBlineSynth.noteOff(note, accent, slide)
	print("Note Off " .. "Note: " .. note)
end


local Output = {}


Output.outputFunctions = {}
Output.outputFunctions[1] = deviceBlineSynth


-- Current output device table
Output.outputDevice = {}
Output.outputDevice = Output.outputFunctions[1]

Output.outputDevice.noteOn(64, 100)
Output.outputDevice.noteOff(64, 100)

