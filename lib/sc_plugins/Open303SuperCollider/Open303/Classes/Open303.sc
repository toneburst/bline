Open303 : UGen {

	// Required parameters:
	// Note number: int 0-127 (MIDI note number)
	// Note velocity: int 0-127 (MIDI note velocity. Sending velocity = 0 is note-off)
	
	// 'noteevent' parameter going positive will trigger a new Open303 note event (noteOn or noteOff)
	// noteevent must go positive for only one k-rate cycle for each note-on/off received!!
	// Defaults values from Open303VST.cpp starting at line 14
	*ar{ | gate = 0.0, notenum = 60.0, notevel = 64.0, notealloff = 0.0, waveform = 0.85, cutoff = 0.229, resonance = 0.5, envmod = 0.25, decay = 0.5, accent = 0.5, volume = 0.9, filtermorph = 0.0, filterdrive = 0.0, distortion = 0.0 |
      ^this.multiNew('audio', gate, notenum, notevel, notealloff, waveform, cutoff, resonance, envmod, decay, accent, volume, filtermorph, filterdrive, distortion);
    }

	checkInputs {		
		// Input rate-checking
        [0, 1].do { |i|
            (inputs[i].rate != 'audio').if {
                ^"input % is not audio rate".format(i).throw;
            };
        };

		^this.checkValidInputs;
	}
}
