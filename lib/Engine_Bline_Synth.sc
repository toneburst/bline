// CroneEngine_Bline
// Crappy 303
Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	var waveform = 1;
	var cutoff = 250;
	var resonance = 0.5;
	var filterDist = 0.0;
	var decay = 2.5;
	var mod = 2;
	var accent = 0.75;
	var slideTime = 0.2;
	var accentDecay = 0.4;
	var accThreshold = 0.9;
	var dist = 0;
	var amp = 0.5;
	var pan = 0;

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
			amp = 0.5, pan = 0,
			gate = 0, velocity = 0,
			freq = 440, freqLagTime = 0.2, freqLagCurve = -2, detune = 0,
			waveform = 0, subLvl = 0,
			ffreq = 250, ffreqMod = 2, ffreqDcy = 20, fRes = 0.75, fDist = 0,
			ampAtk = 0.001, ampRel = 0.1,
			accent = 0.75, accThreshold = 0.9, accAmp = 1.0, accFfreqMod = 3.0, accDcy = 0.3,
			dist = 0|

			// Declare vars
			var sig, freqLagged, accentSwitch, ampEnv, vcfEnv, cutoffModAmt, finalCutoff, finalAmp;

			// Osc freq, with linear lag on legato notes
			freqLagged = VarLag.kr(freq, freqLagTime, freqLagCurve);
			//freqLagged = [freqLagged, freqLagged + (freqLagged * detune)];

			// Oscillator mix pulse > saw
			sig = XFade2.ar(Mix.new(PulseDPW.ar(freqLagged)), Mix.new(SawDPW.ar(freqLagged)), LinLin.ar(waveform, 0.0, 1.0, -1.0, 1.0));

			// Accent switch
			accentSwitch = Select.kr(velocity > accThreshold, [0, 1]);

			// Amp envelope
			ampEnv = EnvGen.kr(
				Env.asr(
					attackTime: ampAtk,
					sustainLevel: 1.0,
					releaseTime: ampRel,
					curve: -4.0
			), gate, doneAction: 0);

			// Filter/Amp accent envelope
			vcfEnv = EnvGen.kr(
				Env.perc(
					attackTime: ampAtk,
					releaseTime: Select.kr(accentSwitch, [ffreqDcy, accDcy]),
					level: 1.0,
					curve: -5.0
				), gate, doneAction: 0);

			// Calculate filter cutoff env mod unaccented/accented
			cutoffModAmt = ffreqMod + ((accFfreqMod * accent) * accentSwitch);

			// Calculate final filter cutoff
			finalCutoff = ffreq + (ffreq * (vcfEnv * cutoffModAmt));
			finalCutoff = finalCutoff.clip(80, 5500);

			// Amp unaccented/accented (add VCF envelope to AMP env)
			finalAmp = (ampEnv + ((vcfEnv * accAmp) * accentSwitch)) * amp;

			// Filter oscillator
			sig = RLPFD.ar(sig, finalCutoff, fRes, fDist, mul:1.0);

			// Distortion
			sig = (sig * linlin(dist, 0, 1, 1, 30)).distort * XFade2.kr(1, 0.2, dist);

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
			waveform = msg[1].linlin(0, 127, 0, 1);
			bline.set(\waveform, waveform);
		});

		this.addCommand("cutoff", "f", { arg msg;
			cutoff = msg[1].linexp(0, 127, 70, 2000);
			bline.set(\ffreq, cutoff);
		});

		this.addCommand("resonance", "f", { arg msg;
			resonance = msg[1].linlin(0, 127, 0, 0.7;
			bline.set(\fRes, resonance);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			filterDist = msg[1].linlin(0, 127, 0, 4);
			bline.set(\fDist, filterDist);
		});

		this.addCommand("envelope", "f", { arg msg;
			mod = msg[1].linlin(0, 127, 0.01, 40);
			bline.set(\ffreqMod, mod);
		});

		this.addCommand("decay", "f", { arg msg;
			decay = msg[1].linexp(0, 127, accentDecay, 2);
			bline.set(\ffreqDcy, decay);
		});

		this.addCommand("accent", "f", { arg msg;
			accent = msg[1].linlin(0, 127, 0, 2);
			bline.set(\accent, accent);
		});

		this.addCommand("distortion", "f", { arg msg;
			dist = msg[1].linlin(0, 127, 0, 1);
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
