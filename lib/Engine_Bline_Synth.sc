// CroneEngine_Bline
// Crappy 303
Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	var p_waveform    = 0.85;
	var p_sublevel    = 0.0;
	var p_cutoff      = 0.229;
	var p_resonance   = 0.5;
	var p_envmod      = 0.25;
	var p_decay       = 0.5;
	var p_accent      = 0.5;
	var p_volume      = 0.9;
	var p_filtermorph = 0.0;
	var p_filterdrive = 0.0;
	var p_dist        = 0.0;
	var p_pan         = 0.0;

	// Note-stack list. Will contain MIDI note numbers of all currently-held keys
	var notestack;

	// Synth instance
	var bline;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		pg = ParGroup.tail(context.xg);

		notestack = List.new();

        //////////////////
        // Define Synth //
        //////////////////

		SynthDef("Open303Bass", {
			arg out     = 0,
			gate        = 0.0,
			notenum     = 60.0,
			notevel     = 64.0,
			waveform    = 0.85,
			sublevel    = 0.0,
			cutoff      = 0.229,
			resonance   = 0.5,
			envmod      = 0.25,
			decay       = 0.5,
			accent      = 0.5,
			volume      = 0.9,
			filtermorph = 0.0,
			filterdrive = 0.0,
			dist        = 0.0,
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

			// Distortion (with naive volume-compensation)
			sig = (sig * linexp(dist, 0, 1, 1, 30)).distort * dist.linexp(0, 1, 1, 0.15);

			// Output output
			Out.ar(out, Pan2.ar(sig, pan, 1.0));
		}).add;

		// https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		// Instantiate synth
		bline = Synth("Open303Bass", target:pg);
		bline.set(
			\gate,        0,
			\waveform,    p_waveform,
			\sublevel,    p_waveform,
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
			//bline.set(\notealloff, 1);
		});

		this.addCommand("note_on", "ii", { arg msg;
			// Add new note to note-stack
			notestack.add(msg[1]);
			// Set synth gate high, update note number and velocity
			bline.set(\gate, 1.0, \notenum, msg[1], \notevel, msg[2]);
			if (notestack.size == 1) {
				postf("SCLANG NOTEON % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
			} {
				postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
			}
		});

		this.addCommand("note_off", "i", { arg msg;
			// Seach for note index in note-stack and remove
			notestack.do({ arg item, i; if (item == msg[1]) { notestack.removeAt(i); }});
			// Check if this we've just released the last held note
			if (notestack.size == 0) {
				// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
				postf("SCLANG LAST NOTE OFF % STACK SIZE % STACK % \n", msg[1], notestack.size, notestack);
				bline.set(\gate, 0.0, \notenum, msg[1]);
			} {
				// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
				postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", notestack.last, notestack.size, notestack);
				bline.set(\gate, 1.0, \notenum, notestack.last);
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

		this.addCommand("distortion", "f", { arg msg;
			p_dist = msg[1].linexp(0, 127, 0, 1);
			bline.set(\dist, p_dist);
		});

		this.addCommand("slide_time", "f", { arg msg;
			//freqLagTime = msg[1].linexp(0, 127, 0.1, 5);
			//bline.set(\freqLagTime, freqLagTime);
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
