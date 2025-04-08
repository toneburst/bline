( // SynthDef

s.waitForBoot {
	SynthDef.new("AcidBass", {
		arg out,
		gate        = 0.0,
		notenum     = 60.0,
		notevel     = 64.0,
		waveform    = 0.85,
		cutoff      = 0.229,
		resonance   = 0.5,
		envmod      = 0.25,
		decay       = 0.5,
		accent      = 0.5,
		volume      = 0.9,
		filtermorph = 0.0,
		filterdrive = 0.0,
		pan         = 0.0;

		// Declare vars
		var notealloff = NamedControl.tr(\notealloff);
		// Create output
		var sig;

		// Synth. Requires Open303_SuperCollider extension from:
		// https://github.com/toneburst/Open303_SuperCollider/tree/main
		sig = Open303.ar(
			gate, notenum, notevel, notealloff,
			waveform, cutoff, resonance, envmod, decay, accent, volume,
			filtermorph, filterdrive
		);

		// Output output
		Out.ar(out, Pan2.ar(sig, pan, 1.0));
	}).add;
};

)

( // Start it

// We need to setup a "mono-legato" note-handling system so that the synth can correctly add slides to overlapping notes.
// Create note-stack list. This will contain MIDI note numbers of all currently-held keys
~notestack = List[];

// Create bassline synth object
~bassline = Synth(\AcidBass);

// Start MIDI
MIDIClient.init;
MIDIIn.connectAll;

// MIDI functions
MIDIFunc.noteOn({ |vel, num|
	// Add new note to note-stack
	~notestack.add(num);
	// If note-stack size is now 1, this is a non-legato note
	if (~notestack.size == 1) {
		// Switch gate high and update synth MIDI note index and velocity. Synth will play note
		//postf("SCLANG NOTEON % STACK SIZE % STACK % \n", num, ~notestack.size, ~notestack);
		~bassline.set(\gate, 1.0, \notenum, num, \notevel, vel);
	} {
		// ...else this is a legato note
		// Hold gate high and update synth note number and velocity. Synth will slide to new note
		//postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", num, ~notestack.size, ~notestack);
		~bassline.set(\gate, 1.0, \notenum, num, \notevel, vel);
	}
});

MIDIFunc.noteOff({ |vel, num|
	// Seach for note index in note-stack and remove
	~notestack.do({ arg item, i; if (item == num) { ~notestack.removeAt(i); }});
	// Check if this we've just released the last held note
	if (~notestack.size == 0) {
		// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
		//postf("SCLANG LAST NOTE OFF % STACK SIZE % STACK % \n", num, ~notestack.size, ~notestack);
		~bassline.set(\gate, 0.0, \notenum, num);
	} {
		// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
		//postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", ~notestack.last, ~notestack.size, ~notestack);
		~bassline.set(\gate, 1.0, \notenum, ~notestack.last);
	}
});

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\waveform, val / 127);
}, ccNum:21);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\cutoff, val / 127);
}, ccNum:22);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\resonance, val / 127);
}, ccNum:23);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\envmod, val / 127);
}, ccNum:24);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\decay, val / 127);
}, ccNum:25);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\accent, val / 127);
}, ccNum:26);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\volume, val / 127);
}, ccNum:27);

MIDIFunc.cc({ |val, ccNum, chan, src|
	~bassline.set(\filtermorph, val / 127);
}, ccNum:28);

)

// Stop it
~bassline.free;
MIDIdef.freeAll;
