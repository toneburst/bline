// CroneEngine_Bline
// 303 Emulaton based on Open303
// Requires Open303_SuperCollider extension from:
// https://github.com/toneburst/Open303_SuperCollider

Engine_Bline_Synth : CroneEngine {

	//var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	var p_waveform    = 0.85;
	var p_sublevel    = 0.0;
	var p_slidetime   = 0.1;
	var p_cutoff      = 0.229;
	var p_resonance   = 0.5;
	var p_envmod      = 0.25;
	var p_decay       = 0.5;
	var p_accent      = 0.5;
	var p_volume      = 0.9;
	var p_filtermorph = 0.0;
	var p_filterdrive = 0.0;
	var p_dist        = -1.0;
	var p_pan         = 0.0;

	// Note-stack list. Will contain MIDI note numbers of all currently-held keys
	var notestack;

	// Synth instance
	var bline;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		//pg = ParGroup.tail(context.xg);

		notestack = List.new();

        //////////////////
        // Define Synth //
        //////////////////

		SynthDef("Open303Bass", {
			arg out,
			gate        = 0.0,
			notenum     = 60.0,
			notevel     = 64.0,
			waveform    = 0.85,
			sublevel    = 0.0,
			slidetime   = 0.1,
			cutoff      = 0.229,
			resonance   = 0.5,
			envmod      = 0.25,
			decay       = 0.5,
			accent      = 0.5,
			volume      = 1.0,
			filtermorph = 0.0,
			filterdrive = 0.0,
			dist        = 0.0,
			pan         = 0.0;

			//////////////////
			// Declare Vars //
			//////////////////

			// Output
			var signal;
			var signal2;
			// Trigger for all-notes-off message to plugin
			var notealloff = NamedControl.tr(\notealloff);

			////////////////////
			// Generate Audio //
			////////////////////

	
			// Distortion (with naive volume-compensation)
			//signal = (signal * linexp(dist, 0, 1, 1, 30)).distort * dist.linexp(0, 1, 1, 0.15);

			// Output output
			//Out.ar(out, Pan2.ar(signal, pan));
	
			// Simple sinewave synth to test SynthDef
			var env = Env.adsr(0.01, 1.0, 0.75, 0.5).ar(gate: gate);
			signal = SinOsc.ar(notenum);	

			// Synth. Requires Open303_SuperCollider extension from:
			// https://github.com/toneburst/Open303_SuperCollider/tree/main
			signal2 = Open303.ar(
				gate, notenum, notevel, notealloff,
				waveform, cutoff, resonance, envmod, decay, accent, volume,
				filtermorph, filterdrive
			);
			Out.ar(out, Pan2.ar(signal2, pan, 1.0));

		}).add;

		// https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		// Instantiate synth
		//bline = Synth("Open303Bass", target:pg);
		bline = Synth("Open303Bass");
		bline.set(
			\gate,        0,
			\waveform,    p_waveform,
			\sublevel,    p_waveform,
			\slidetime,   p_slidetime,
			\cutoff,      p_cutoff,
			\resonance,   p_resonance,
			\envmod,      p_envmod,
			\decay,       p_decay,
			\accent,      p_accent,
			\volume ,     p_volume,
			\filtermorph, p_filtermorph,
			\filterdrive, p_filterdrive,
			\dist,        p_dist,
			\pan,         p_pan
		);

        ///////////////////////
        // Control Interface //
        ///////////////////////

		this.addCommand("all_notes_off", "i", { arg msg;
			notestack = [];
			bline.set(\notealloff, 1);
		});

		this.addCommand("note_on", "ii", { arg msg;
			// Add new note to note-stack
			notestack = notestack.add(msg[1]);
			// If note-stack size is now 1, this is a non-legato note
			if (notestack.size == 1) {
				// Switch gate high and update synth MIDI note index and velocity. Synth will play note
				postf("SCLANG NOTEON % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
				bline.set(\gate, 1.0, \notenum, msg[1], \notevel, msg[2]);
				//bline.set(\gate, 1.0, \notenum, msg[1].midicps, \notevel, msg[2]);
			} {
				// ...else this is a legato note
				// Hold gate high and update synth note number and velocity. Synth will slide to new note
				postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
				bline.set(\gate, 1.0, \notenum, msg[1], \notevel, msg[2]);
				//bline.set(\gate, 1.0, \notenum, msg[1].midicps, \notevel, msg[2]);
			}
		});

		this.addCommand("note_off", "i", { arg msg;
			// Seach for note index in note-stack and remove
			notestack = notestack.do({ arg item, i; if (item == msg[1]) { notestack.removeAt(i); }});
			// Check if this we've just released the last held note
			if (notestack.size == 0) {
				// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
				postf("SCLANG LAST NOTE OFF % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
				bline.set(\gate, 0.0, \notenum, msg[1]);
			} {
				// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
				postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", notestack.last, notestack.size, notestack);
				bline.set(\gate, 1.0, \notenum, notestack.last);
				//bline.set(\gate, 1.0, \notenum, (notestack.last).midicps);
			}
		});

		this.addCommand("waveform", "f", { arg msg;
			p_waveform = msg[1].linlin(0, 127, 0, 1);
			bline.set(\waveform, p_waveform);
		});

		this.addCommand("sub_level", "f", { arg msg;
			p_sublevel = msg[1].linlin(0, 127, -1, -0.75);
			//bline.set(\sublevel, p_sublevel);
		});

		this.addCommand("cutoff", "f", { arg msg;
			p_cutoff = msg[1].linexp(0, 127, 0, 1);
			bline.set(\cutoff, p_cutoff);
		});

		this.addCommand("resonance", "f", { arg msg;
			p_resonance = msg[1].linlin(0, 127, 0, 1);
			bline.set(\resonance, p_resonance);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			p_filterdrive = msg[1].linlin(0, 127, 0, 1);
			bline.set(\filterdrive, p_filterdrive);
		});

		this.addCommand("envelope", "f", { arg msg;
			p_envmod = msg[1].linexp(0, 127, 0, 1);
			bline.set(\envmod, p_envmod);
		});

		this.addCommand("decay", "f", { arg msg;
			p_decay = msg[1].linexp(0, 127, 0, 1);
			bline.set(\decay, p_decay);
		});

		this.addCommand("accent", "f", { arg msg;
			p_accent = msg[1].linlin(0, 127, 0, 1);
			bline.set(\accent, p_accent);
		});

		this.addCommand("filter_morph", "f", { arg msg;
			p_filtermorph = msg[1].linlin(0, 127, 0, 1);
			bline.set(\filtermorph, p_filtermorph);
		});

		this.addCommand("distortion", "f", { arg msg;
			p_dist = msg[1].linexp(0, 127, -1, 1);
			bline.set(\dist, p_dist);
		});

		this.addCommand("slide_time", "f", { arg msg;
			p_slidetime = msg[1].linexp(0, 127, 0, 1);
			bline.set(\slidetime, p_slidetime);
		});

		this.addCommand("volume", "f", { arg msg;
			p_volume = msg[1].linlin(0, 127, 0, 1);
			bline.set(\volume, p_volume);
		});

		this.addCommand("pan", "f", { arg msg;
			p_pan = msg[1].linlin(0, 127, -1, 1);
			bline.set(\pan, p_pan);
		});

	} // end alloc

	free {
		bline.free;
	}

} // end class
