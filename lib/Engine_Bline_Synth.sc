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
	var p_bline_accdcy = 0.3;
	var p_bline_accthreshold;

	// Open303 core synth params (see synthDef for default param values)
	var p_o303_waveform;
	var p_o303_cutoff;
	var p_o303_resonance;
	var p_o303_envmod;
	var p_o303_decay;
	var p_o303_accent;
	var p_o303_distortion;
	var p_o303_volume;
	var p_o303_pan;
	// Additional params
	var p_o303_filtermorph;
	var p_o303_sublevel;
	var p_o303_slidetime;

	// Distortion params
	var p_dist_tone;
	var p_dist_drive;
	var p_dist_mix;

	// Chorus params
	var p_chorus_rate;
	var p_chorus_depth;
	var p_chorus_mix;

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
			arg outbus,
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

			// Output
			Out.ar(outbus, [sig, sig], finalAmp);
		}).add;

		// Define Open303 Synth
		SynthDef("Open303Bass", {
			arg outbus,
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
			//sig = sig * resonance.linexp(1, 0, 1, 0.25);
			
			// Final output
			Out.ar(outbus, [sig, sig], 1.0);

		}).add;

		// Define Distortion FX
		SynthDef.new("FXDistortion", {
			arg inbus,
			type          = 0,
			distdrive     = 0.5,
			disttone      = 0.5,
			res           = 0.1,
			noise         = 0.0003,
			fxmix         = 1.0,
			outbus;

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

			Out.ar(outbus, [sig, sig]);
		}).add;

		// Define Chorus FX
		SynthDef.new("FXChorus", {
			arg inbus,
			chorusrate      = 0.5,
			chorusdepth     = 0.5,
			chorusphasediff = 0.9,
			fxmix           = 0.5,
			outbus;

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

			Out.ar(outbus, [sig, sig], 1.0);

		}).add;

		// Define Output FX
		SynthDef.new("FXOutput", {
			arg inbus,
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
		fx_bus = Bus.audio(context.server, 2);

		////////////////////////
		// Instantiate Synths //
		////////////////////////

		// OG synth
		blinesynth = Synth("BlineBass");
		blinesynth.set(\outbus, fx_bus);

		// Open303 synth
		o303synth = Synth.after(blinesynth, "Open303Bass");
		o303synth.set(\outbus, fx_bus);

		// Add Distortion FX
		distortion = Synth.after(o303synth, "FXDistortion");
		distortion.set(\inbus, fx_bus, \outbus, fx_bus);

		// Add Chorus FX
		chorus = Synth.after(distortion, "FXChorus");
		chorus.set(\inbus, fx_bus, \outbus, fx_bus);

		// Add Output
		output = Synth.after(chorus, "FXOutput");
		output.set(\inbus, fx_bus, \out, 0);

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
			//p_bline_distortion = msg[1].linlin(0, 127, -1, 1);
			//blinesynth.set(\distortion, p_bline_distortion);
		});

		this.addCommand("slide_time", "f", { arg msg;
			p_bline_slidetime = msg[1].linexp(0, 127, 0.1, 5);
			blinesynth.set(\slidetime, p_bline_slidetime);
		});

		this.addCommand("volume", "f", { arg msg;
			//p_bline_volume = msg[1].linlin(0, 127, 0, 1);
			//blinesynth.set(\volume, p_bline_volume);
		});

		this.addCommand("pan", "f", { arg msg;
			//p_bline_pan = msg[1].linlin(0, 127, -1, 1);
			//blinesynth.set(\pan, p_bline_pan);
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
			//o303synth.set(\distortion, p_o303_distortion);
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
			//o303synth.set(\pan, p_o303_pan);
		});

	} // end alloc

	free {
		blinesynth.free;
		o303synth.free;
	}

} // end class
