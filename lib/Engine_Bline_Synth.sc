// CroneEngine_Bline
// Crappy 303
Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	var waveform = 1; // -1 to 1 range
	var detune = 0;
	var subLevel = -1; // -1 to 0 range
	var cutoff = 250;
	var resonance = 0.3;
	var filterDist = 0;
	var decay = 2;
	var mod = 0.5;
	var accent = 0.75;
	var slideTime = 0.2;
	var accentDecay = 0.3;
	var accThreshold = 0.9;
	var dist = -1;  // -1 to 1 range

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

		// Set initial params (may not be needed (use Norns param default values?))
		bline = Synth(\bline, [
			\out, 0,
			\gate, 0,
			\amp, amp,
			\waveform, waveform,
			\ffreq, cutoff,
			\ffreqDcy, decay,
			\ffreqMod, mod,
			\accent, accent,
			\accDcy, accentDecay,
			\accThreshold, accThreshold,
			\freqLagTime, slideTime,
			\dist, dist],
		target:pg);

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
				bline.set(\freqLagTime, slideTime);
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
			waveform = msg[1].linlin(0, 127, -1, 1);
			bline.set(\waveform, waveform);
		});

		this.addCommand("cutoff", "f", { arg msg;
			cutoff = msg[1].linexp(0, 127, 30, 4000);
			bline.set(\ffreq, cutoff);
		});

		this.addCommand("resonance", "f", { arg msg;
			resonance = msg[1].linlin(0, 127, 0.1, 0.8;
			bline.set(\fRes, resonance);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			filterDist = msg[1].linlin(0, 127, 0, 4);
			bline.set(\fDist, filterDist);
		});

		this.addCommand("envelope", "f", { arg msg;
			mod = msg[1].linlin(0, 127, 0.1, 1);
			bline.set(\ffreqMod, mod);
		});

		this.addCommand("decay", "f", { arg msg;
			decay = msg[1].linexp(0, 127, accentDecay, 4);
			bline.set(\ffreqDcy, decay);
		});

		this.addCommand("accent", "f", { arg msg;
			accent = msg[1].linlin(0, 127, 0, 1);
			bline.set(\accent, accent);
		});

		this.addCommand("distortion", "f", { arg msg;
			dist = msg[1].linlin(0, 127, -1, 1);
			bline.set(\dist, dist);
		});

		this.addCommand("slide_time", "f", { arg msg;
			slideTime = msg[1]; // No interpolation!
			bline.set(\freqLagTime, slideTime);
		});

		this.addCommand("volume", "f", { arg msg;
			slideTime = msg[1].linlin(0, 127, 0, 1);
			bline.set(\amp, amp);
		});

		this.addCommand("pan", "f", { arg msg;
			pan = msg[1].linlin(0, 127, -1, 1);
			bline.set(\pan, pan);
		});

	} // end alloc

	free {
		bline.free;
	}

} // end class
