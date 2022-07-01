# clockcut

simple demonstration of clocked looping / delay with `softcut` on norns

## usage

at present, the demo has no interactive UI. it exposes parameters which are designed for MIDI mapping.

## parameters

- `clock_mul`: multiplied by the clock beat duration to yield loop duration

- `speed_ratio`: speed of the virtual tape, as a ratio

- `speed_tune`: speed tuning offset, in cents

- `rec_level`: level at which input is written to the buffer

- `pre_level`: level at which existing buffer contents are preserved

- `fade_ms`: crossfade duration in milliseconds

### EQ parameters

this script includes an `EQ` class which attempts to provide more usable controls for softcut's state variable filter.

- `eq_mix`: wet/dry mix

- `eq_tilt`: -1 = lowpass, +1 = highpass

- `eq_select`: mix in bandpass/bandreject. for positive values, this acts as gain around FC; for negative values it doens't (yet) act as a parametric cut; rather it brings in frequencies outside of the tilt control in addition to supressing around FC.

- `eq_rez`: resonance control. also could use some scaling work

## TODO:

- raw midi clock mode (handle PPQ ticks directly)
- internal looping mode (ignore clock and division sequence)
- tweak EQ parameters

- trigger params to reset, clear, etc

- more voices (somehow)
- feedback routing (somehow)

- duration sequences
- position sequences?

- more UI:
  - display: show phase, etc
  - input: control parameters directly (assignable/meta?)
