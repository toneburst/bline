// CroneEngine_Bline
// Crappy 303
Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	params = Dictionary.newFrom([
		\waveform, 1, // -1 to 1 range
		\detune, 0,
		\subLevel, -1, // -1 to 0 range
		\cutoff, 250,
		\resonance, 0.3,
		\filterDist, 0,
		\decay, 2,
		\mod, 0.5,
		\accent, 0.75,
		\slideTime, 0.2,
		\accDcy, 0.3,
		\accThreshold, 0.9,
		\dist, -1  // -1 to 1 range
	]);

	// var waveform = 1; // -1 to 1 range
	// var detune = 0;
	// var subLevel = -1; // -1 to 0 range
	// var cutoff = 250;
	// var resonance = 0.3;
	// var filterDist = 0;
	// var decay = 2;
	// var mod = 0.5;
	// var accent = 0.75;
	// var slideTime = 0.2;
	// var accentDecay = 0.3;
	// var accThreshold = 0.9;
	// var dist = -1;  // -1 to 1 range

	// Active notes array
	var activeFreqs;

	var bline;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		pg = ParGroup.tail(context.xg);

		activeFreqs = Array.new(10);

        //////////////////
        // Define Synth //
        //////////////////

		SynthDef(\bline, { |out = 0,
			amp = 0.8, pan = 0,
			gate = 0, velocity = 0,
			freq = 440, freqLagTime = 0, freqLagCurve = -2, detune = 0,
			waveform = 1, subLvl = -1,
			ffreq = 250, maxFfreqMod = 4500, ffreqAtk = 0.0001, accFfreqAtk = 0.005, ffreqDcy = 2, ffreqMod = 0.5, fRes = 0.75, fDist = 0,
			ampAtk = 0.0001, ampDcy = 8.0, ampRel = 0.01,
			accent = 0.75, accThreshold = 0.9, accAmp = 1.5, accFfreqMod = 500, accDcy = 0.3,
			dist = -1 |

			// Define vars
			var sig, freqLagged, accentSwitch, ampEnv, vcfEnv, cutoffModAmt, finalCutoff, finalAmp;

			// Osc freq, with linear lag on legato notes
			freqLagged = VarLag.kr(freq, freqLagTime, freqLagCurve);

			// Oscillator mix pulse > saw
			sig = XFade2.ar(PulseDPW.ar(freqLagged), SawDPW.ar(freqLagged), waveform);

			// Mix in sub-osc
			sig = XFade2.ar(sig, PulseDPW.ar(0.5 * freqLagged), subLvl);

			// Accent switch
			accentSwitch = Select.kr(velocity > accThreshold, [0, 1]);

			// Amp envelope
			ampEnv = EnvGen.kr(
				Env.adsr(
					attackTime: ampAtk,
					decayTime: ampDcy,
					sustainLevel: 0.0,
					releaseTime: ampRel,
					curve: -4.0
			), gate, doneAction: 0);

			// Filter/Amp accent envelope
			vcfEnv = EnvGen.kr(
				Env.perc(
					attackTime: Select.kr(accentSwitch, [ffreqAtk, accFfreqAtk]), // Soften VCF env attack on accented notes?
					releaseTime: Select.kr(accentSwitch, [ffreqDcy, accDcy]),
					level: 1.0,
					curve: -4.0
				), gate, doneAction: 0);

			// Calculate filter cutoff env mod unaccented/accented
			cutoffModAmt = (ffreqMod * maxFfreqMod) + (accentSwitch * (accent * accFfreqMod));

			// Calculate final filter cutoff
			finalCutoff = ffreq + (vcfEnv * cutoffModAmt);
			finalCutoff = finalCutoff.clip(50, 4000);

			// Amp unaccented/accented (add VCF envelope to AMP env)
			finalAmp = (ampEnv + (accentSwitch * (vcfEnv * accAmp))) * amp;

			// Filter oscillator
			sig = RLPFD.ar(sig, finalCutoff, fRes, fDist, mul:1.5);

			// Distortion
			sig = (sig * linlin(dist, -1, 1, 1, 30)).distort * LinXFade2.kr(1, 0.2, dist);

			// Output
			Out.ar(out, Pan2.ar(sig, pan, finalAmp));
		}).add;


		// https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		bline = Synth(\bline, params.getPairs, target:pg);


        ///////////////////////
        // Control Interface //
        ///////////////////////

		this.addCommand("all_notes_off", "i", { arg msg;
			activeFreqs = [];
			bline.set(\gate, 0);
		});

		this.addCommand("note_on", "ii", { arg msg;
			var freq = msg[1].midicps;
			if(activeFreqs.isEmpty) {
				// Non-Legato note
				bline.set(\gate, 1, \velocity, msg[2]/127, \freqLagTime, 0);
			} {
				// Legato note
				bline.set(\freqLagTime, params.slideTime);
			};
			bline.set(\freq, freq);
			activeFreqs = activeFreqs.add(freq);
		});

		this.addCommand("note_off", "i", { arg msg;
			var freq = msg[1].midicps;
			activeFreqs.remove(freq);
			if(activeFreqs.isEmpty) {
				// Non-legato release
				bline.set(\freq, freq, \gate, 0);
			} {
				// Legato release
				bline.set(\freq, activeFreqs.last);
			};
		});

		this.addCommand("waveform", "f", { arg msg;
			params.waveform = msg[1].linlin(0, 127, -1, 1);
			bline.set(\waveform, params.waveform);
		});

		this.addCommand("cutoff", "f", { arg msg;
			params.cutoff = msg[1].linexp(0, 127, 30, 4000);
			bline.set(\ffreq, params.cutoff);
		});

		this.addCommand("resonance", "f", { arg msg;
			params.resonance = msg[1].linlin(0, 127, 0.1, 0.8;
			bline.set(\fRes, params.resonance);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			params.filterDist = msg[1].linlin(0, 127, 0, 4);
			bline.set(\fDist, params.filterDist);
		});

		this.addCommand("envelope", "f", { arg msg;
			params.mod = msg[1].linlin(0, 127, 0.1, 1);
			bline.set(\ffreqMod, params.mod);
		});

		this.addCommand("decay", "f", { arg msg;
			params.decay = msg[1].linexp(0, 127, params.accentDecay, 4);
			bline.set(\ffreqDcy, params.decay);
		});

		this.addCommand("accent", "f", { arg msg;
			params.accent = msg[1].linlin(0, 127, 0, 1);
			bline.set(\accent, params.accent);
		});

		this.addCommand("distortion", "f", { arg msg;
			params.dist = msg[1].linlin(0, 127, -1, 1);
			bline.set(\dist, params.dist);
		});

		this.addCommand("slide_time", "f", { arg msg;
			params.slideTime = msg[1]; // No interpolation!
			bline.set(\freqLagTime, params.slideTime);
		});

		this.addCommand("volume", "f", { arg msg;
			params.amp = msg[1].linlin(0, 127, 0, 1);
			bline.set(\amp, params.amp);
		});

		this.addCommand("pan", "f", { arg msg;
			params.pan = msg[1].linlin(0, 127, -1, 1);
			bline.set(\pan, params.pan);
		});

	} // end alloc

	free {
		bline.free;
	}

} // end class
