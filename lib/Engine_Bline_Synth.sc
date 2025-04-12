// CroneEngine_Bline
// Crappy 303
Engine_Bline_Synth : CroneEngine {

	var pg;

	//////////////////////////
	// Default Param Values //
	//////////////////////////

	var amp = 0.8;
	var pan = 0;
	var waveform = 1;
	var subLvl = -1;
	var freqLagTime = 0.2;
	var fFreq = 250;
	var fRes = 0.3;
	var fDist = 0;
	var fFreqDcy = 2;
	var fFreqMod = 0.5;
	var accent = 0.75;
	var accDcy = 0.3;
	var accThreshold = 0.9;
	var dist = -1;

	// Active notes array
	var activeFreqs;

	// Synth instance
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

		SynthDef("bline", {
			arg out = 0,
			amp = 0.8, pan = 0,
			gate = 0, velocity = 0,
			freq = 440, freqLagTime = 0, freqLagCurve = -2, detune = 0,
			waveform = 1, subLvl = -1,
			fFreq = 250, maxfFreqMod = 4000, fFreqAtk = 0.0001, accfFreqAtk = 0.005, fFreqDcy = 2, fFreqMod = 0.5, fRes = 0.75, fDist = 0,
			ampAtk = 0.0001, ampDcy = 8.0, ampRel = 0.01,
			accent = 0.75, accThreshold = 0.9, accAmp = 1.25, accfFreqMod = 750, accDcy = 0.3,
			dist = -1;

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
					attackTime: Select.kr(accentSwitch, [fFreqAtk, accfFreqAtk]), // Soften VCF env attack on accented notes?
					releaseTime: Select.kr(accentSwitch, [fFreqDcy, accDcy]),
					level: 1.0,
					curve: -4.0
				), gate, doneAction: 0);

			// Calculate filter cutoff env mod unaccented/accented
			cutoffModAmt = (fFreqMod * maxfFreqMod) + (accentSwitch * (accent * accfFreqMod));

			// Calculate final filter cutoff
			// Envelope contribution
			finalCutoff = fFreq + (vcfEnv * cutoffModAmt);
			// Clip cuttoff frequency to min/max (RLPFD filter seems to alias badly over about 4000Hz, unfortunately)
			finalCutoff = finalCutoff.clip(50, 6000);

			// Amp unaccented/accented (add VCF envelope to AMP env on accented notes)
			finalAmp = (ampEnv + (accentSwitch * (vcfEnv * accAmp)));
			// Scale to amp param. Naive resonance volume compensation (seems to work OK though)
			finalAmp = finalAmp * fRes.linlin(0.1, 0.8, 0.7 * amp, amp);

			// Filter oscillator
			sig = RLPFD.ar(sig, finalCutoff, fRes, fDist, mul:1.5);

			// Distortion (with naive volume-compensation)
			sig = (sig * linexp(dist, -1, 1, 1, 30)).distort * dist.linexp(-1, 1, 1, 0.15);

			// Output
			Out.ar(out, Pan2.ar(sig, pan, finalAmp));
		}).add;

		// https://llllllll.co/t/supercollider-engine-failure-in-server-error/53051
		Server.default.sync;

		bline = Synth("bline", target:pg);
		bline.set(
			\pan, pan,
			\waveform, waveform,
			\subLvl, subLvl,
			\freqLagTime, freqLagTime,
			\fFreq, fFreq,
			\fRes, fRes,
			\fDist, fDist,
			\fFreqDcy, fFreqDcy,
			\fFreqMod, fFreqMod,
			\accent, accent,
			\accDcy, accDcy,
			\accThreshold, accThreshold
		);

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
				bline.set(\freqLagTime, freqLagTime);
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

		this.addCommand("sub_level", "f", { arg msg;
			subLvl = msg[1].linlin(0, 127, -1, -0.75);
			bline.set(\subLvl, subLvl);
		});

		this.addCommand("cutoff", "f", { arg msg;
			fFreq = msg[1].linexp(0, 127, 30, 4000);
			bline.set(\fFreq, fFreq);
		});

		this.addCommand("resonance", "f", { arg msg;
			fRes = msg[1].linlin(0, 127, 0.1, 0.8);
			bline.set(\fRes, fRes);
		});

		this.addCommand("filter_overdrive", "f", { arg msg;
			fDist = msg[1].linlin(0, 127, 0, 4);
			bline.set(\fDist, fDist);
		});

		this.addCommand("envelope", "f", { arg msg;
			fFreqMod = msg[1].linexp(0, 127, 0.1, 1);
			bline.set(\fFreqMod, fFreqMod);
		});

		this.addCommand("decay", "f", { arg msg;
			fFreqDcy = msg[1].linexp(0, 127, accDcy, 4);
			bline.set(\fFreqDcy, fFreqDcy);
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
			freqLagTime = msg[1].linexp(0, 127, 0.1, 5);
			bline.set(\freqLagTime, freqLagTime);
		});

		this.addCommand("volume", "f", { arg msg;
			amp = msg[1].linlin(0, 127, 0, 1);
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
