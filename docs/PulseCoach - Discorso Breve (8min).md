# PulseCoach: Short Presentation Speech (8 min)

> Condensed script for two presenters, to be read start to finish
> (about 8 minutes at a calm pace, roughly 4 minutes each).
> **Paolo** presents Part 1 (slides 1 to 8): the problem, the product, and how it
> adapts. **Daniel** presents Part 2 (slides 9 to 18): trust, the design system,
> social, architecture, and privacy. The **▸ Slide N** headings tell you when to advance.

---

## Part 1 — Paolo

### ▸ Slide 1: Title

Good morning. I'm Paolo, this is Daniel, and we built **PulseCoach** to fix a small
problem that quietly wrecks most people's fitness goals.

The whole idea fits in one line: *Move more. Decide less.* It's an AI-adaptive
micro-workout coach that plans your day so you don't have to. Three short sessions,
tuned to how your body feels that morning.

### ▸ Slide 2: Agenda

I'll cover the problem and the product, and how the coach adapts to you. Then
Daniel takes trust, the design system, and privacy.

### ▸ Slide 3: The problem

Here's the core insight: people don't quit exercising because the workout is too
hard. They quit because *deciding* is hard.

Every session in a typical app starts with a wall of choices. What today, how long,
how intense, which of forty routines. That's a planning tax, and you pay it before
a single push-up. Roughly **half** of new fitness-app users lapse within a month,
and you're often looking at **six or more taps** before you even start moving. The
enemy here isn't effort. It's friction.

### ▸ Slide 4: The opportunity

Three things make this the right moment. First, micro-workouts actually work. Short
"exercise snacks" of two to ten minutes show real benefit and fit a real day.
Second, the signals are everywhere: resting heart rate, steps, and recent effort
already stream from the phone and wearable people carry. And third, AI now runs on
the device, so we can personalize locally. That's adaptive coaching without ever
shipping health data to a server.

### ▸ Slide 5: Introducing PulseCoach

So here it is. PulseCoach picks **three short sessions every day**, one mobility,
one cardio, one breathing, and tunes each to how you feel, using on-device signals
plus context like weather and air quality. You open the app, and about thirty
seconds later you're moving. The only decision we leave you is the one that
matters: to start.

### ▸ Slide 6: Our vision

In one phrase, the vision is **zero-planning fitness**. We remove the planning tax
entirely, so consistency stops depending on willpower and starts depending on
something much simpler: just opening the app.

### ▸ Slide 7: How it works

Let me walk the loop. It senses on-device signals like heart rate, steps, and
recent effort, plus the weather and how hard yesterday felt. Then it adapts, and
this is the key part: it is not a fixed plan. Intensity, duration, and the mix of
sessions are all tuned to your readiness today. A rough night gets you a gentler
day. Feeling strong gets you more. Then you move, three sessions, each with a
plain-language reason you can trust.

Then the loop closes. After each session you tap how hard it felt, and that feeds
straight into tomorrow's plan. Under the hood it's a real learning system: a
behavioural state machine, a hard safety layer that can always override it, and a
small reinforcement-learning agent that gets better the more you use it.

### ▸ Slide 8: The daily ritual

All of that collapses into one calm screen. The **Today** screen shows exactly one
thing to do next. At the top, a behavioural-state header reading your readiness. In
the middle, a completion ring for your three sessions. And front and centre, the
hero card: the next session, one tap to start.

One screen, one decision. I'll hand over to Daniel for trust, design, and privacy.

*(handoff: Paolo to Daniel)*

---

## Part 2 — Daniel

### ▸ Slide 9: The coach voice

Thanks, Paolo. Here's what really sets PulseCoach apart: the coach always explains
itself. You never get a vague "we adjusted your workout." You get something like:
*"Intensity reduced today: high perceived effort yesterday, short recovery,
elevated resting heart rate. Let's lighten the load to recover."*

And that explanation is generated from the exact signals the engine actually used.
It's the real reasoning made readable, not marketing copy bolted on afterwards.
Transparency builds trust, and trust is what keeps people coming back.

### ▸ Slide 10: Design philosophy

The interface is a **calm, dark-first cockpit** for a five-minute workout. It's
quiet on purpose. Four principles drive it. Dark-first, for low glare while you
move. No shadows, so depth comes from subtle surface tints instead. One accent, a
single teal that carries every action. And spinner-free, with shimmer skeletons
instead of loaders. The result is that your next session is always the loudest
thing on the screen.

### ▸ Slide 11: Color

The colour discipline is strict. **Teal** is the primary, and it carries every
action, all your progress, the completion ring. Violet and amber are the only other
accents, reserved for behavioural states and difficulty. And a nice detail: the
brand colours are identical in dark and light mode. Only the surfaces flip.

### ▸ Slide 12: Typography

Two font families, kept strictly separate. **Plus Jakarta Sans** handles everything
you read. **JetBrains Mono** handles data and only data: timers, heart rate, RPE.
It's a hard rule, not a suggestion. The moment you see a monospaced number, you
know it's a live reading.

### ▸ Slide 13: Components

And none of this is a mockup. These are live components from the actual design
system, one shared library of fifteen. Every screen composes from the same source
of truth, which is why design and code stay in lockstep.

### ▸ Slide 14: Screens

Those components make four core screens. **Today** you've seen. **Sessions** is a
filterable catalog of everything you can do. **Progress** shows your weekly goal and
your effort trend. The fourth tab, **Social**, I'll come back to in a second. Every
one is built from the same components, which is what makes the whole thing feel like
one calm product instead of four separate screens.

### ▸ Slide 15: Move more, together

Most of the app is a solo experience by design. But there's the **social** tab, and
it's worth calling out because of how carefully we scoped it. You add friends with a
QR code, see each other move in a shared feed, compare progress, even start a
session in sync. There's a leaderboard too. But none of it is built to shame you.
There are no streaks to break, and the leaderboard **freezes your rank the moment
the coach puts you in recovery**, so a rough week never drops you down the board.
Competition never overrides the coach.

### ▸ Slide 16: Architecture

Before we get to privacy, one slide on how the system is actually built, because the
boundary here is the whole point. The adaptive core, the learning agent, the safety
layer, your health signals, the local database, all of it runs on the phone. Nothing
about your body ever crosses that line. Outside it sit a few external services, and
they only ever feed value inward: Open-Meteo gives us weather and air quality with no
personal data attached, and ExerciseDB supplies the exercise catalog, cached so it
works offline. The one cloud layer, realtime social, backup, subscriptions, is a Pro
feature and strictly opt-in, and it never carries raw health data. Keep that line in
mind, because it's exactly what the next slide is about.

### ▸ Slide 17: Privacy by design

Which brings us to privacy, and we treat it as a genuine feature, not a footnote.
**All of your health data lives on your device.** The adaptive AI runs locally, and
nothing is sent to a server, ever. The app doesn't even need a network to learn.

And this matters more every year. Health signals are a **special category under
GDPR**, and shipping your biometrics to a server for an opaque plan back is becoming
a liability. We built the opposite, and we can be concrete about it. Location is
reduced to **city level** before any weather call. The optional backup uploads only
**end-to-end-encrypted** ciphertext. There's **no account** required to use the
core. And the right to be forgotten and to export your data aren't a paragraph in a
policy page. They're functions that actually run.

Here's the part we find elegant. Privacy and explainability come from the same
decision. Because everything runs locally, the reason we show you is projected from
the exact signals the engine used, not reconstructed from a remote model you can't
see. On-device is what makes both the trust and the transparency possible, and in a
category built entirely on sensitive health signals, that's a real competitive edge.

### ▸ Slide 18: Closing

So let me bring us back to where we started. Most fitness apps lose people at the
decision, not the effort. PulseCoach removes that planning tax, so staying
consistent stops depending on willpower and starts depending on simply opening the
app.

And this isn't a concept. It's a feature-complete, working application, with an
on-device adaptive engine, a full design system, and around fourteen hundred
automated tests behind it, all passing.

*Move more. Decide less.* That's PulseCoach. Thank you. We'd be happy to take your
questions.

---

## Appendix — Anticipated Q&A

**"Isn't on-device an ideological choice that costs you quality? A cloud model
would learn better."**
No, it's a constraint we turned into a feature. The bandit learns on-device from
your perceived effort without ever needing the network, and that's exactly what
makes the explainability possible: the reason we surface comes from the same signals
the engine consumes, not a remote model you can't inspect. Privacy and
explainability are the same decision, not two separate trade-offs.

**"Is this real learning, or just if-else rules?"**
It's a genuine online learner, an ε-greedy multi-armed bandit that updates its
policy from the RPE you report after each session. We deliberately wrap it in a
deterministic safety gate: the learner only ever chooses within the actions the
safety rules have already declared admissible. So it adapts, but it can never adapt
its way into an unsafe recommendation.

**"How is this different from existing adaptive fitness apps?"**
The concept of an adaptive coach isn't new. The architecture is. Existing apps
delegate the intelligence to the cloud. PulseCoach runs the entire decision engine
on-device, safety-gated and explainable, with no account and no network required to
learn.
