# Audio Routing, Monitoring & Effects — Requirements

> Source: voice memo (Argentine Spanish), transcribed and summarized.
> This captures the intended behavior for input routing, monitoring, and
> non-destructive effects in the multitrack / looper engine.

## Summary — what we want

A **multitrack looper** with **always-clean recording + non-destructive post
effects**, where each input has a separate **recording route** and **live
monitoring route**, with chainable effects applied differently on each route.

## Requirements

1. **Non-destructive effects.** Effects are *never* "printed" onto the input
   when recording. What gets recorded on the track is the clean signal, so the
   effect can later be changed/tweaked without losing the original.

2. **Each input records to its own independent track.** If two inputs are
   assigned to one track, they are **not merged** on record: they stay separate
   and both play back.

3. **Two distinct routes per input (separate channels):**
   - **Recording route (track):** input → goes clean (*no effects*) to the
     track; effects are applied at the track, and from there to the output.
   - **Input-monitoring route:** input → straight to output, and on *that*
     channel effects can be applied (e.g. a delay) that **go only to the output
     and are never recorded**.

4. **Monitoring is independent of playback.** The input→output channel works
   even if the track already has something recorded and playing; they are
   separate signals.

5. **Chainable effects (stacking).** Effects can be stacked in series
   (FX1 → FX2 → …), taking the output of one effect as the input of the next,
   at the track output.

6. **Tracks stack in two dimensions:** by **loop layers** (classic looper
   behavior) *and* by **number of inputs**.

## Signal flow

```
                 ┌─────────────────────────── Recording route ───────────────────────────┐
  input (in1) ───┤  (clean, "no effects")  →  TRACK  →  track effects (FX1 → FX2 → …)  →  OUTPUT
                 └─────────────────────────────────────────────────────────────────────────┘
                 ┌──────────────────────── Input-monitoring route ────────────────────────┐
  input (in1) ───┤  monitor channel  →  monitor effects (e.g. delay, never recorded)  →   OUTPUT
                 └─────────────────────────────────────────────────────────────────────────┘
```

- The signal recorded on the track is **always clean** (effects are applied on
  playback / at the track, not on the way in).
- The monitoring channel to the output is **independent** of whether the track
  already has a recording playing.
- Per-input choice: e.g. `in1` → track 1 with two effects applied at the track;
  `in2` → routed straight to the output.

## Worked example

- `in1` and `in2` both feed track 1.
- `in1`: apply two effects (at the track, non-destructive).
- `in2`: route directly to the output.
- Track 1's recorded content stays clean; effects sit on the track/output path.

---

## Full transcription (English)

**[00:00]** Okay, again: I have different inputs. I don't want to apply effects
to the input directly, because if I apply effects to the input directly, what
gets recorded in the track is the input *with* the effect. Then, after I record,
if I want to make any change to that effect, I can't. That's why I don't do it
destructively.

**[00:29]** Also, what I need is for each track to be recorded individually on
its own track. If I select two inputs for one track, when I record they
shouldn't be merged: they have to be recorded independently, and then, on
playback, both play.

**[00:58]** Then, when the track plays, the effect can be applied to it. And I
also want to be able to apply effects to the input when I select it for *input
monitoring*. Input monitoring is: I grab and select an input and tell it "okay,
route this input to the output," right?

**[01:27]** All good. But if you want to use an input with an effect, that should
also be possible. And that's where this comes in: the input-with-effect goes
directly to the output, but the input-with-effect is never recorded. You get it?
The [routing] channels are different.

**[01:56]** You have an input that on one side goes to a track, right? The input
going to the track is the "no effects" one, and only at the track do the effects
get applied, and that goes to the output.

**[02:25]** Then, the input itself, if I select it for monitoring, can also go to
the output. And there, on that channel, I can also apply an effect. This effect
—say, a delay— never goes to the track, it goes directly to the output. That's
input monitoring: you monitor the input.

**[02:54]** The other thing wouldn't make sense, because what comes out of the
track only comes out once there's already a recording here.

**[03:23]** Get it? That is, this channel that goes to the output is independent
of whether track 1 already has something recorded and playing. It's not the
input's sound going to the output.

**[03:52]** That's the other route. Get it? If you want to apply an effect to
your input, and then on that result you want to apply another effect, you can
stack them here: FX2. Where? At the track output, at the FX1 output.

**[04:21]** The track output comes out clean, from there it goes to the effects
channels, right? And from there it goes to the output. Or… no, not exactly: the
track output doesn't come out clean, the track output comes out [with…].

**[04:50]** First you have, let's say, `in1` and `in2` coming into track 1,
right? To `in1` I want to apply these two effects. `in2` I want to route
straight out, right?

**[05:19]** So, the output of track 1 is clean sound, it passes through *input
effects* applied at the track…

**[05:48]** …because it doesn't apply to all the tracks. So the tracks aren't
only stacked by loop layers, they're stacked by loop layers *and* by number of
inputs, right?

**[06:17]** To me it makes sense. Okay.

> Note: a few passages marked `[…]` were unclear in the source audio.
