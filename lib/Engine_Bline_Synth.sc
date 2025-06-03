// CroneEngine_Bline
// 303 Emulaton based on Open303
// Requires Open303_SuperCollider extension from:
// https://github.com/toneburst/Open303_SuperCollider

Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////
	// Declare Vars //
	//////////////////

	// Bus to pass synth output to FX
	var fx_bus;
	// Note-stack array for OG Bline synth. Will contain frequencies of all currently-held keys
	var bline_notestack;
	// Note-stack list for Open303 synth. Will contain MIDI note numbers of all currently-held keys
	var o303_notestack;
	// OG synth instance
	var blinesynth;
	// Open303 synth instance
	var o303synth;
	// FX instances
	var distortion, chorus, output;

	// Bline synth parameters
	var p_bline_slidetime;
	var p_bline_accdcy = 0.3;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		pg = ParGroup.tail(context.xg);

		fx_bus = Bus.audio(context.server, 2);
		bline_notestack = List.new();
		o303_notestack  = List.new();

        ///////////////////
        // Define Synths //
        ///////////////////

		// Define original Bline synth
		SynthDef("BlineBass", {
			arg enabled     =  0,
			outbus          =  0,
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
			volume			=  0.75;

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

			// Output (send to LEFT channel of FX bus)
			Out.ar(outbus, sig, finalAmp * enabled);
		}).add;

		// Define Open303 Synth
		SynthDef("Open303Bass", {
			arg enabled = 0,
			outbus  	= 0,
			gate        = 0.0,
			notenum     = 60.0,
			notevel     = 64.0,
			waveform    = 0.0,
			cutoff      = 0.229,
			resonance   = 0.5,
			envmod      = 0.25,
			decay       = 0.5,
			accent      = 0.5,
			volume      = 0.75,
			// Additional (non 303-original) params
			filtermorph = 0.0,
			sublevel    = 0.0,	// Not yet implemented
			slidetime   = 0.1;	// Not yet implemented

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
				filtermorph:	filtermorph
			);
			
			// Resonance naive volume-compensation (replaced with compressor + limiter over entire output)
			sig = sig * resonance.linexp(1, 0, 1, 0.25);
			
			// Output (send to RIGHT channel of FX bus)
			Out.ar(outbus, sig, enabled);

		}).add;

		// Define Distortion FX
		SynthDef.new("FXDistortion", {
			arg inbus     = 0,
			type          = 0,
			distdrive     = 0.5,
			disttone      = 0.5,
			res           = 0.1,
			noise         = 0.0003,
			fxmix         = 1.0,
			outbus        = 0;

			var freq, filtertype, sig, wet;

			// Dry input from bus
			sig = In.ar(inbus, 1);

			// Adapted from overdrive and distortion FX by 21echoes:
			// https://github.com/21echoes/pedalboard/tree/master

			// Wet signal. First we feed into a HPF to filter out sub-20Hz
			wet = HPF.ar(sig, 25);

			// ...then we feed into selectable overdrive/distortion
			wet = Select.ar(type > 0.5, [
				// Drive controls 1 to 5x the volume with soft-clipping
				(wet * LinLin.kr(distdrive, 0, 1, 1, 5)).softclip,
				// Drive controls 1 to 5x the volume with hard-clipping
				(wet * LinExp.kr(distdrive, 0, 1, 1, 5)).distort
			]);

			// ...then into the Tone section
			// Tone controls a MMF, exponentially ranging from 10 Hz - 21 kHz
			// Tone above 0.75 switches to a HPF
			freq = Select.kr(disttone > 0.75, [
				Select.kr(disttone > 0.2, [
					LinExp.kr(disttone, 0, 0.2, 10, 400),
					LinExp.kr(disttone, 0.2, 0.75, 400, 20000),
				]),
				LinExp.kr(disttone, 0.75, 1, 20, 21000),
			]);

			// ...finally we feed the signal into the filter section
			// Switch filter-type
			filtertype = Select.kr(disttone > 0.75, [0, 1]);
			wet = DFM1.ar(
				in:          wet,
				freq:        freq,
				res:         res,
				inputgain:   1.0,
				type:        filtertype,
				noiselevel:  noise
			).softclip;

			// Naive level-compensation
			wet = LinLin.ar(distdrive, 0, 1, 0.5, 0.25) * wet;

			// Wet/dry mix distorted and dry signals
			sig = XFade2.ar(sig, wet, fxmix);

			Out.ar(outbus, sig);
		}).add;

		// Define Chorus FX
		// TODO: Change this to a Flanger to allow feedback, and stereo-ise
		// https://github.com/21echoes/pedalboard/blob/master/lib/fx/Flanger.sc
		SynthDef.new("FXChorus", {
			arg inbus       = 0,
			chorusrate      = 0.5,
			chorusdepth     = 0.5,
			chorusphasediff = 0.9,
			fxmix           = 0.5,
			outbus          = 0;

			var numdelays = 4, lfos, rate, depth, maxdelaytime, mindelaytime, sig, wet;

			// Dry input from bus
			sig = In.ar(inbus, 1);

			// Adapted from chorus FX by 21echoes:
			// https://github.com/21echoes/pedalboard/tree/master

			rate = chorusrate;
			rate = Select.kr(rate > 0.5, [
				LinExp.kr(rate, 0.0, 0.5, 0.025, 0.125),
				LinExp.kr(rate, 0.5, 1.0, 0.125, 2)
			]);

			depth = chorusdepth;
			maxdelaytime = LinLin.kr(depth, 0.0, 1.0, 0.016, 0.052);
			mindelaytime = LinLin.kr(depth, 0.0, 1.0, 0.012, 0.022);

			wet = sig * numdelays.reciprocal;
			lfos = Array.fill(numdelays, {|i|
				LFPar.kr(
					rate * {rrand(0.95, 1.05)},
					chorusphasediff * i,
					(maxdelaytime - mindelaytime) * 0.5,
					(maxdelaytime + mindelaytime) * 0.5,
				)
			});
			wet = DelayC.ar(wet, (maxdelaytime * 2), lfos).sum;

			sig = XFade2.ar(sig, wet, fxmix);

			Out.ar(outbus, sig, 1.0);

		}).add;

		// Define Output FX
		SynthDef.new("FXOutput", {
			arg inbus   = 0,
			pan			= 0,
			volume		= 1.0,
			out			= 0;

			var sig;

			// Dry input from bus
			sig = In.ar(inbus, 1);

			// Add Compressor
			sig = Compander.ar(
				in:				sig,
				control:		sig,
				thresh:			0.25,
				slopeBelow:		1,
				slopeAbove:		0.5,
				clampTime:		0.01,
				relaxTime:		0.01
			);
			
			// Add limiter
			sig = Limiter.ar(
				in:				sig,
				level:			0.9,
				dur:			0.01	// Lookahead time (ms)
			);

			// Pass signal to final output, with volume and pan control
			Out.ar(out, Pan2.ar(sig, pan, volume));
		}).add;

		// Sync server
		// See: https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		//////////////////
		// Setup FX Bus //
		//////////////////

		// Create FX bus
		// Bus is Stereo. Our synths and FX are mono currently, so we will copy the signal to both channels at the output stage of each synth/FX
		fx_bus = Bus.audio(context.server, 1);

		////////////////////////
		// Instantiate Synths //
		////////////////////////

		// OG synth
		blinesynth = Synth("BlineBass", target:pg);
		blinesynth.set("outbus", fx_bus);

		// Open303 synth
		o303synth = Synth.after(blinesynth, "Open303Bass", target:pg);
		o303synth.set("outbus", fx_bus);

		// Add Distortion FX
		distortion = Synth.after(o303synth, "FXDistortion", target:pg);
		distortion.set("inbus", fx_bus, "outbus", fx_bus);

		// Add Chorus FX
		chorus = Synth.after(distortion, "FXChorus", target:pg);
		chorus.set("inbus", fx_bus, "outbus", fx_bus);

		// Add Output
		output = Synth.after(chorus, "FXOutput", target:pg);
		output.set("inbus", fx_bus, "out", 0);

		//////////////////
		// Select Synth //
		//////////////////

		// Enable/disable synth output
		// 1 = both off, 2 = Bline, 3 = Open303
		this.addCommand("source_select", "i", { arg msg;
			var src = msg[1];
			if( src == 2 ) { blinesynth.set("enabled", 1); } { blinesynth.set("enabled", 0) };
			if( src == 3 ) {  o303synth.set("enabled", 1); } {  o303synth.set("enabled", 0) };
		});

		///////////////////////
		// OG Synth Commands //
		///////////////////////

		// Note On/Off
		this.addCommand("note_on", "ii", { arg msg;
			var freq = msg[1].midicps;
			// Add new note to note-stack
			bline_notestack = bline_notestack.add(freq);	
			// If note-stack size is now 1, this is a non-legato note
			if(bline_notestack.size == 1) {
				// Non-Legato note
				blinesynth.set("gate", 1, "velocity", msg[2]/127, "slidetime", 0);
			} {
				// ...else this is a legato note
				blinesynth.set("slidetime", p_bline_slidetime);
			};
			blinesynth.set("freq", freq);
		});

		this.addCommand("note_off", "i", { arg msg;
			var freq = msg[1].midicps;
			// Seach for freq index in note-stack and remove
			bline_notestack = bline_notestack.do({ arg item, i; if (item == freq) { bline_notestack.removeAt(i); }});
			// Check if this we've just released the last held note
			if (bline_notestack.size == 0) {
				// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
				blinesynth.set("freq", freq, "slidetime", 0, "gate", 0);
			} {
				// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
				blinesynth.set("freq", bline_notestack.last, "slidetime", p_bline_slidetime);
			};
		});

		this.addCommand("all_notes_off", "i", { arg msg;
			bline_notestack = [];
			blinesynth.set("gate", 0);
		});

		// Parameters
		this.addCommand("waveform", "f", { arg msg;
			blinesynth.set("waveform", msg[1].linlin(0, 127, -1, 1));
		});

		this.addCommand("sub_level", "f", { arg msg;
			blinesynth.set("sublevel", msg[1].linlin(0, 127, -1, -0.75));
		});

		this.addCommand("cutoff", "f", { arg msg;
			blinesynth.set("cutoff", msg[1].linexp(0, 127, 30, 4000));
		});

		this.addCommand("resonance", "f", { arg msg;
			blinesynth.set("resonance", msg[1].linlin(0, 127, 0.1, 0.8));
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			blinesynth.set("filterdrive", msg[1].linlin(0, 127, 0, 4));
		});

		this.addCommand("envelope", "f", { arg msg;
			blinesynth.set("envmod", msg[1].linexp(0, 127, 0.1, 1));
		});

		this.addCommand("decay", "f", { arg msg;
			blinesynth.set("decay", msg[1].linexp(0, 127, p_bline_accdcy, 4));
		});

		this.addCommand("accent", "f", { arg msg;
			blinesynth.set("accent", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("distortion", "f", { arg msg;
			//blinesynth.set("distortion", msg[1].linlin(0, 127, -1, 1));
		});

		this.addCommand("slide_time", "f", { arg msg;
			p_bline_slidetime = msg[1].linexp(0, 127, 0.1, 5);
			blinesynth.set("slidetime", p_bline_slidetime);
		});

		this.addCommand("volume", "f", { arg msg;
			output.set("volume", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("pan", "f", { arg msg;
			output.set("pan", msg[1].linlin(0, 127, -1, 1));
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
				o303synth.set("gate", 1, "notenum", msg[1], "notevel", msg[2]);
			} {
				// ...else this is a legato note
				// Hold gate high and update synth note number and velocity. Synth will slide to new note
				o303synth.set("gate", 1, "notenum", msg[1], "notevel", msg[2]);
			}
		});

		this.addCommand("o303_note_off", "i", { arg msg;
			// Seach for note index in note-stack and remove
			o303_notestack = o303_notestack.do({ arg item, i; if (item == msg[1]) { o303_notestack.removeAt(i); }});
			// Check if this we've just released the last held note
			if (o303_notestack.size == 0) {
				// ...we have. Pull gate low and send note index to synth (velocity not required). Synth will release note
				o303synth.set("gate", 0, "notenum", msg[1]);
			} {
				// Notes still held. Update synth with most recent note index remaining in note-stack. Synth will slide back to note
				o303synth.set("gate", 1, "notenum", o303_notestack.last);
			}
		});

		this.addCommand("o303_all_notes_off", "i", { arg msg;
			o303_notestack = [];
			o303synth.set("notealloff", 1);
		});

		// Parameters
		this.addCommand("o303_waveform", "f", { arg msg;
			o303synth.set("waveform", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_sub_level", "f", { arg msg;
			//o303synth.set("sublevel", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_cutoff", "f", { arg msg;
			o303synth.set("cutoff", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_resonance", "f", { arg msg;
			o303synth.set("resonance", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_filter_morph", "f", { arg msg;
			o303synth.set("filtermorph", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_envelope", "f", { arg msg;
			o303synth.set("envmod", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_decay", "f", { arg msg;
			o303synth.set("decay", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_accent", "f", { arg msg;
			o303synth.set("accent", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_distortion", "f", { arg msg;
			//o303synth.set("distortion", msg[1].linlin(0, 127, -1, 1));
		});

		this.addCommand("o303_slide_time", "f", { arg msg;
			//o303synth.set("slidetime", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_volume", "f", { arg msg;
			output.set("volume", msg[1].linlin(0, 127, 0, 1));
		});

		this.addCommand("o303_pan", "f", { arg msg;
			output.set("pan", msg[1].linlin(0, 127, -1, 1));
		});

	} // end alloc

	free {
		blinesynth.free;
		o303synth.free;
		distortion.free;
		chorus.free;
		output.free;
	}

} // end class
