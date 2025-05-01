// CroneEngine_Bline
// 303 Emulaton based on Open303
// Requires Open303_SuperCollider extension from:
// https://github.com/toneburst/Open303_SuperCollider

Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	// Original Bline core synth params (see synthDef for default param values)
	var p_bline_waveform;
	var p_bline_sublevel;
	var p_bline_slidetime;
	var p_bline_cutoff;
	var p_bline_resonance;
	var p_bline_filterdrive;
	var p_bline_envmod;
	var p_bline_decay;
	var p_bline_accent;
	var p_bline_distortion;
	var p_bline_volume;
	var p_bline_pan;
	// Additional params
	var p_bline_accdcy;
	var p_bline_accthreshold;

	// Open303 core synth params (see synthDef for default param values)
	var p_o303_waveform;
	var p_o303_sublevel;
	var p_o303_slidetime;
	var p_o303_cutoff;
	var p_o303_resonance;
	var p_o303_filterdrive;	// Not yet implemented (not sure what range of values to use)
	var p_o303_envmod;
	var p_o303_decay;
	var p_o303_accent;
	var p_o303_distortion;
	var p_o303_volume;
	var p_o303_pan;
	// Additional params
	var p_o303_filtermorph;

	// Note-stack array for OG Bline synth. Will contain frequencies of all currently-held keys
	var bline_notestack;
	
	// Note-stack list for Open303 synth. Will contain MIDI note numbers of all currently-held keys
	var o303_notestack;

	// OG synth instance
	var blinesynth;

	// Open303 synth instance
	var o303synth;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		pg = ParGroup.tail(context.xg);

		bline_notestack = List.new();
		o303_notestack  = List.new();

        ///////////////////
        // Define Synths //
        ///////////////////

		// Define original Bline synth
		SynthDef("BlineBass", {
			arg out			=  0,
			gate			=  0,
			velocity		=  0,
			freq			=  440,
			slidetime		=  0,
			slidecurve		= -2,
			detune			=  0,
			waveform		=  1,
			sublevel		= -1,
			cutoff			=  250,
			maxenvmod		=  4000,
			cutoffatk		=  0.0001,
			acccutoffatk	=  0.005,
			decay			=  2,
			envmod			=  0.5,
			resonance		=  0.75,
			filterdrive		=  0,
			ampatk			=  0.0001,
			ampdcy			=  8.0,
			amprel			=  0.01,
			accent			=  0.75,
			accthreshold	=  0.9,
			accamp			=  1.25,
			accenvmod		=  750,
			accdcy			=  0.3,
			distortion		= -1,
			volume			=  0.8,
			pan				=  0;

			// Declare synth internal vars
			var sig, freqLagged, accentSwitch, ampEnv, vcfEnv, envmodAmt, finalCutoff, finalAmp;

			// Osc freq, with linear lag on legato notes
			freqLagged = VarLag.kr(freq, slidetime, slidecurve);

			// Oscillator mix pulse > saw
			sig = XFade2.ar(PulseDPW.ar(freqLagged), SawDPW.ar(freqLagged), waveform);

			// Mix in sub-osc
			sig = XFade2.ar(sig, PulseDPW.ar(0.5 * freqLagged), sublevel);

			// Accent switch
			accentSwitch = Select.kr(velocity > accthreshold, [0, 1]);

			// Amp envelope
			ampEnv = EnvGen.kr(
				Env.adsr(
					attackTime: ampatk,
					decayTime: ampdcy,
					sustainLevel: 0.0,
					releaseTime: amprel,
					curve: -4.0
			), gate, doneAction: 0);

			// Filter/Amp accent envelope
			vcfEnv = EnvGen.kr(
				Env.perc(
					attackTime: Select.kr(accentSwitch, [cutoffatk, acccutoffatk]), // Soften VCF env attack on accented notes?
					releaseTime: Select.kr(accentSwitch, [decay, accdcy]),
					level: 1.0,
					curve: -4.0
				), gate, doneAction: 0);

			// Calculate filter cutoff env mod unaccented/accented
			envmodAmt = (envmod * maxenvmod) + (accentSwitch * (accent * accenvmod));

			// Calculate final filter cutoff
			// Envelope contribution
			finalCutoff = cutoff + (vcfEnv * envmodAmt);
			// Clip cuttoff frequency to min/max (RLPFD filter seems to alias badly over about 4000Hz, unfortunately)
			finalCutoff = finalCutoff.clip(50, 6000);

			// Amp unaccented/accented (add VCF envelope to AMP env on accented notes)
			finalAmp = (ampEnv + (accentSwitch * (vcfEnv * accamp)));
			// Scale to amp param. Naive resonance volume compensation (seems to work OK though)
			finalAmp = finalAmp * resonance.linlin(0.1, 0.8, 0.7 * volume, volume);

			// Filter oscillator
			sig = RLPFD.ar(sig, finalCutoff, resonance, filterdrive, mul:1.5);

			// Distortion (with naive volume-compensation)
			sig = (sig * linexp(distortion, -1, 1, 1, 30)).distort * distortion.linexp(-1, 1, 1, 0.15);

			// Output
			Out.ar(out, Pan2.ar(sig, pan, finalAmp));
		}).add;

		// Define Open303 Synth
		SynthDef("Open303Bass", {
			arg out		= 0,
			gate        = 0.0,
			notenum     = 60.0,
			notevel     = 64.0,
			waveform    = 0.0,
			sublevel    = 0.0,	// Not yet implemented
			slidetime   = 0.1,	// Not yet implemented
			cutoff      = 0.229,
			resonance   = 0.5,
			envmod      = 0.25,
			decay       = 0.5,
			accent      = 0.5,
			volume      = 1.0,
			filtermorph = 0.0,
			filterdrive = -1.0,	// Not yet implemented (not sure what range of values to use)
			distortion	= 0.0,
			pan         = 0.0;

			// Declare synth internal vars

			var notealloff = NamedControl.tr(\notealloff);	// Trigger for all-notes-off message to plugin
			var sig;	// Output signal

			// Generate Audio

			// Synth. Requires Open303_SuperCollider extension from:
			// https://github.com/toneburst/Open303_SuperCollider/tree/main
			sig = Open303.ar(
				gate:			gate,
				notenum:		notenum,
				notevel:		notevel,
				notealloff:		notealloff,
				waveform:		waveform,
				cutoff:			cutoff,
				resonance:		resonance,
				envmod:			envmod,
				decay:			decay,
				accent:			accent,
				volume:			volume,
				filtermorph:	filtermorph,
				filterdrive:	filterdrive
			);
			
			// Resonance naive volume-compensation (replaced with compressor + limiter over entire output)
			//sig = sig * resonance.linexp(1, 0, 1, 0.25);
			
			// Add distortion with naive volume-compensation
			// TODO: Replace with analog-style distortion using plugin
			sig = (sig * linexp(distortion, -1, 1, 1, 30)).distort * distortion.linexp(-1, 1, 1, 0.15);
			
			// Add Compressor
			sig = Compander.ar(
				in:				sig,
				control:		sig,
				thresh:			0.5,
				slopeBelow:		1,
				slopeAbove:		0.5,
				clampTime:		0.01,
				relaxTime:		0.01
			);
			
			// Add limiter
			sig = Limiter.ar(sig, 0.9, 0.01);
			
			// Final output
			Out.ar(out, Pan2.ar(sig, pan, 1.0));

		}).add;

		// Sync server
		// See: https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		////////////////////////
		// Instantiate Synths //
		////////////////////////

		// OG synth
		blinesynth = Synth("BlineBass");

		// Open303 synth
		o303synth = Synth("Open303Bass");

		///////////////////////
		// OG Synth Commands //
		///////////////////////

		// Note On/Off
		this.addCommand("note_on", "ii", { arg msg;
			var freq = msg[1].midicps;
			if(bline_notestack.isEmpty) {
				// Non-Legato note
				blinesynth.set(\gate, 1, \velocity, msg[2]/127, \slidetime, 0);
			} {
				// Legato note
				blinesynth.set(\slidetime, p_bline_slidetime);
			};
			blinesynth.set(\freq, freq);
			bline_notestack = bline_notestack.add(freq);
		});

		this.addCommand("note_off", "i", { arg msg;
			var freq = msg[1].midicps;
			bline_notestack.remove(freq);
			if(bline_notestack.isEmpty) {
				// Non-legato release
				blinesynth.set(\freq, freq, \gate, 0);
			} {
				// Legato release
				blinesynth.set(\freq, bline_notestack.last);
			};
		});

		this.addCommand("all_notes_off", "i", { arg msg;
			bline_notestack = [];
			blinesynth.set(\gate, 0);
		});

		// Parameters
		this.addCommand("waveform", "f", { arg msg;
			p_bline_waveform = msg[1].linlin(0, 127, -1, 1);
			blinesynth.set(\waveform, p_bline_waveform);
		});

		this.addCommand("sub_level", "f", { arg msg;
			p_bline_sublevel = msg[1].linlin(0, 127, -1, -0.75);
			blinesynth.set(\sublevel, p_bline_sublevel);
		});

		this.addCommand("cutoff", "f", { arg msg;
			p_bline_cutoff = msg[1].linexp(0, 127, 30, 4000);
			blinesynth.set(\cutoff, p_bline_cutoff);
		});

		this.addCommand("resonance", "f", { arg msg;
			p_bline_resonance = msg[1].linlin(0, 127, 0.1, 0.8);
			blinesynth.set(\resonance, p_bline_resonance);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			p_bline_filterdrive = msg[1].linlin(0, 127, 0, 4);
			blinesynth.set(\filterdrive, p_bline_filterdrive);
		});

		this.addCommand("envelope", "f", { arg msg;
			p_bline_envmod = msg[1].linexp(0, 127, 0.1, 1);
			blinesynth.set(\envmod, p_bline_envmod);
		});

		this.addCommand("decay", "f", { arg msg;
			p_bline_decay = msg[1].linexp(0, 127, p_bline_accdcy, 4);
			blinesynth.set(\decay, p_bline_decay);
		});

		this.addCommand("accent", "f", { arg msg;
			p_bline_accent = msg[1].linlin(0, 127, 0, 1);
			blinesynth.set(\accent, p_bline_accent);
		});

		this.addCommand("distortion", "f", { arg msg;
			p_bline_distortion = msg[1].linlin(0, 127, -1, 1);
			blinesynth.set(\distortion, p_bline_distortion);
		});

		this.addCommand("slide_time", "f", { arg msg;
			p_bline_slidetime = msg[1].linexp(0, 127, 0.1, 5);
			blinesynth.set(\slidetime, p_bline_slidetime);
		});

		this.addCommand("volume", "f", { arg msg;
			p_bline_volume = msg[1].linlin(0, 127, 0, 1);
			blinesynth.set(\volume, p_bline_volume);
		});

		this.addCommand("pan", "f", { arg msg;
			p_bline_pan = msg[1].linlin(0, 127, -1, 1);
			blinesynth.set(\pan, p_bline_pan);
		});

		////////////////////////////
		// Open303 Synth Commands //
		////////////////////////////

		// Note On/Off
		this.addCommand("o303_note_on", "ii", { arg msg;
			// Add new note to note-stack
			o303_notestack = o303_notestack.add(msg[1]);
			// If note-stack size is now 1, this is a non-legato note
			if (o303_notestack.size == 1) {
				// Switch gate high and update synth MIDI note index and velocity. Synth will play note
				//postf("SCLANG NOTEON % STACK SIZE % STACK % \n", msg[1], o303_notestack.size, o303_notestack);
				o303synth.set(\gate, 1.0, \notenum, msg[1], \notevel, msg[2]);
			} {
				// ...else this is a legato note
				// Hold gate high and update synth note number and velocity. Synth will slide to new note
				//postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", msg[1], o303_notestack.size, o303_notestack);
				o303synth.set(\gate, 1.0, \notenum, msg[1], \notevel, msg[2]);
			}
		});

		this.addCommand("o303_note_off", "i", { arg msg;
			// Seach for note index in note-stack and remove
			o303_notestack = o303_notestack.do({ arg item, i; if (item == msg[1]) { o303_notestack.removeAt(i); }});
			// Check if this we've just released the last held note
			if (o303_notestack.size == 0) {
				// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
				//postf("SCLANG LAST NOTE OFF % STACK SIZE % STACK % \n", msg[1], o303_notestack.size, o303_notestack);
				o303synth.set(\gate, 0.0, \notenum, msg[1]);
			} {
				// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
				//postf("SCLANG SLIDETO % STACK SIZE % STACK % \n", o303_notestack.last, o303_notestack.size, o303_notestack);
				o303synth.set(\gate, 1.0, \notenum, o303_notestack.last);
			}
		});

		this.addCommand("o303_all_notes_off", "i", { arg msg;
			o303_notestack = [];
			o303synth.set(\notealloff, 1);
		});

		// Parameters
		this.addCommand("o303_waveform", "f", { arg msg;
			p_o303_waveform = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\waveform, p_o303_waveform);
		});

		this.addCommand("o303_sub_level", "f", { arg msg;
			p_o303_sublevel =  msg[1].linlin(0, 127, 0, 1);
			//o303synth.set(\sublevel, p_o303_sublevel);
		});

		this.addCommand("o303_cutoff", "f", { arg msg;
			p_o303_cutoff = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\cutoff, p_o303_cutoff);
		});

		this.addCommand("o303_resonance", "f", { arg msg;
			p_o303_resonance = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\resonance, p_o303_resonance);
		});

		this.addCommand("o303_filter_morph", "f", { arg msg;
			p_o303_filtermorph = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\filtermorph, p_o303_filtermorph);
		});

		this.addCommand("o303_envelope", "f", { arg msg;
			p_o303_envmod = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\envmod, p_o303_envmod);
		});

		this.addCommand("o303_decay", "f", { arg msg;
			p_o303_decay = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\decay, p_o303_decay);
		});

		this.addCommand("o303_accent", "f", { arg msg;
			p_o303_accent = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\accent, p_o303_accent);
		});

		this.addCommand("o303_distortion", "f", { arg msg;
			p_o303_distortion = msg[1].linlin(0, 127, -1, 1);
			o303synth.set(\distortion, p_o303_distortion);
		});

		this.addCommand("o303_slide_time", "f", { arg msg;
			p_o303_slidetime = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\slidetime, p_o303_slidetime);
		});

		this.addCommand("o303_volume", "f", { arg msg;
			p_o303_volume = msg[1].linlin(0, 127, 0, 1);
			o303synth.set(\volume, p_o303_volume);
		});

		this.addCommand("o303_pan", "f", { arg msg;
			p_o303_pan = msg[1].linlin(0, 127, -1, 1);
			o303synth.set(\pan, p_o303_pan);
		});

	} // end alloc

	free {
		blinesynth.free;
		o303synth.free;
	}

} // end class
