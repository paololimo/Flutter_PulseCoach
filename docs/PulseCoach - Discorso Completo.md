# PulseCoach: Full Presentation Speech

> Continuous script for two presenters, to be read start to finish
> (about 14 to 15 minutes at a calm pace, roughly 7 minutes each).
> **Paolo** presents Part 1 (slides 1 to 8): the problem, the product, and how it
> adapts. **Daniel** presents Part 2 (slides 9 to 17): trust, the design system,
> social, and privacy. The **▸ Slide N** headings tell you when to advance.

---

## Part 1 — Paolo

### ▸ Slide 1: Title

Good morning. I'm Paolo, and this is Daniel. We want to talk to you about a small
problem that quietly wrecks most people's fitness goals, and about the app we
built to remove it.

It's called **PulseCoach**, and the whole idea fits in one line: *Move more.
Decide less.*

It's an AI-adaptive micro-workout coach. It plans your day so you don't have to.
Three short sessions, tuned to how your body actually feels that morning. I'll
take you through the problem and the product, and then Daniel will walk you
through the design system and how we keep your data private.

### ▸ Slide 2: Agenda

Here's the path. First the problem, and why the market is ready for it. Then the
product itself and the vision. Then the interesting part, which is how the coach
actually adapts to you. And finally a look at the design system: color, type,
components, and how we handle privacy.

### ▸ Slide 3: The problem

So here's the core insight. People don't quit exercising because the workout is
too hard. They quit because *deciding* is hard.

Every session in a typical fitness app starts with a wall of choices. What should
I do today? How long? How intense? Which of these forty routines? That's a
planning tax, and you pay it before you've done a single push-up. And it
compounds. Miss a couple of days, the app starts making you feel guilty, and you
stop opening it altogether.

The numbers back this up. Roughly **half** of new fitness-app users lapse within
the first month. On a normal workday, the median person can protect maybe
**twenty minutes** of free time. And in a planning-first app, you're looking at
**six or more taps and decisions** before you even start moving.

Every one of those taps is a chance to give up. The real enemy here isn't effort.
It's friction.

### ▸ Slide 4: The opportunity

Now, three things make this the right moment to solve it.

**First, micro-workouts actually work.** The research on short, frequent bursts
of movement, the so-called "exercise snacks", shows real cardiometabolic benefit.
And crucially, they fit into a real day. Two to ten minutes, not an hour at the
gym.

**Second, the signals are everywhere.** Resting heart rate, step count, recent
effort. That data already streams from the phone and the wearable people are
already carrying. We don't need new hardware.

**Third, AI now runs on the device.** We can do the personalization locally. That
means adaptive coaching without ever shipping someone's health data to a server.
That intersection of physiology, signals, and on-device AI is exactly where
PulseCoach lives.

### ▸ Slide 5: Introducing PulseCoach

So here it is. PulseCoach picks **three short sessions every day**, one mobility,
one cardio, one breathing, and tunes each of them to how you feel, using
on-device signals plus context like the weather and the air quality.

You open the app, and about thirty seconds later you're moving. The only decision
we leave you is the one that matters: to start.

### ▸ Slide 6: Our vision

If we had to put the vision in one phrase, it's **zero-planning fitness**.

Movement that fits into any life, because the deciding is done for you. We remove
the planning tax entirely, so consistency stops depending on willpower and starts
depending on something much simpler: just opening the app.

### ▸ Slide 7: How it works

This is the part we find most interesting, so let me walk you through the loop
from left to right.

**It senses.** The engine reads on-device signals like resting heart rate, steps,
and your recent effort, plus context like today's weather and air quality, and
how hard yesterday's sessions actually felt to you.

**Then it adapts.** And this is the key point: it is not a fixed plan. The
intensity, the duration, the mix of session types, all of it is tuned to your
readiness today. A rough night's sleep and a high heart rate get you a gentler
day. Feeling strong gets you more.

**Then you move.** Three sessions, and every single one comes with a
plain-language reason you can actually trust.

And then the loop closes. After each session you tell it how hard that felt, a
single tap, and that feedback flows straight back into tomorrow's plan. Under the
hood this is a genuine learning system: a behavioural state machine, a hard safety
layer that can always override it, and a small reinforcement-learning agent that
gets better the more you use it. It keeps learning, quietly, in the background.

### ▸ Slide 8: The daily ritual

All of that intelligence collapses into one calm screen.

You open the app, and the **Today** screen shows you exactly one thing to do
next. Everything else is just quietly tracked.

At the top, a behavioural-state header. That's the coach telling you how it's
reading your readiness this morning. In the middle, a completion ring, so you can
see your three sessions at a glance. And front and centre, the hero card: the
single next session, ready to start with one tap.

*(pause: let them read the screen)*

One screen, one decision. That's the entire interaction on a normal day. And on
that note, I'll hand over to Daniel to talk about trust, design, and privacy.

*(handoff: Paolo to Daniel)*

---

## Part 2 — Daniel

### ▸ Slide 9: The coach voice

Thanks, Paolo. Here's what we think really sets PulseCoach apart. The coach always
explains itself.

Every recommendation comes with an honest, specific reason. Not a vague
"we adjusted your workout", but something like: *"Intensity reduced today: high
perceived effort yesterday, short recovery, and an elevated resting heart rate.
Let's lighten the load to recover."*

*(pause on the quote)*

That matters for two reasons. First, it means the AI feels like a coach you trust
rather than a black box making decisions at you. Second, and this is the important
bit, that same explanation is generated from the exact signals the engine actually
used to decide. It isn't marketing copy bolted on afterwards. It's the real
reasoning, made readable. The coach is gentle on your bad days and celebratory on
your good ones, and it always tells you why. Transparency builds trust, and trust
is what keeps people coming back.

### ▸ Slide 10: Design philosophy

Now let's switch to how it looks and feels, because the design does a lot of the
work here.

The whole interface is built to be a **calm, dark-first cockpit** for a
five-minute workout. It's quiet on purpose: deep near-black navy, a lot of
negative space, flat surfaces.

Four principles drive it. **Dark-first**, so it's low-glare and easy on the eyes
when you're moving. **No shadows**, because depth comes from three subtle surface
tints instead of a drop shadow. **One accent**, a single teal that carries every
action, with other colours reserved for meaning. And **spinner-free**: while
things load, we show shimmer skeletons shaped like the content that's about to
appear.

The result is that your next session is always the loudest thing on the screen.

### ▸ Slide 11: Color

On colour, the discipline is strict. **Teal** is the primary. It carries every
action, all your progress, the completion ring. **Violet and amber** are the only
other accents, and they're reserved for behavioural states and difficulty. Session
types get their own coding too: mobility in teal, cardio in rose, breathing in
violet.

And a nice detail: the brand colours are identical in dark and light mode. Only
the surfaces flip. The identity never changes.

### ▸ Slide 12: Typography

Type follows the same discipline, with two families kept strictly separate.

**Plus Jakarta Sans** handles everything you read: all the UI, all the body copy.
It stays warm and human, one or two short sentences at a time.

And **JetBrains Mono** handles data, and only data. Timers, heart rate, RPE,
counters. It's a hard rule, not a suggestion: numbers should look like data, and
prose never should. The moment you see a monospaced number, you know it's a live
reading.

### ▸ Slide 13: Components

And none of what you've seen is a mockup. These are live components from the
actual design system: the completion ring, the behavioural-state indicator, the
type and difficulty tags, the action buttons.

*(pause: gesture at the components)*

It's one shared library of fifteen components. Every screen, every prototype,
every artifact composes from this same source of truth, which is why design and
code stay perfectly in lockstep.

### ▸ Slide 14: Screens

Put those components together and you get three core screens.

**Today** gives you the state header, the ring, and the hero card Paolo just
showed you. **Sessions** is a filterable catalog of everything you can do. And
**Progress** shows your weekly goal and your effort trend over time.

*(pause: let them scan the three)*

Notice the parallel structure. Every one of these is built from the exact same
components and tokens. That consistency is what makes the whole thing feel like
one calm, coherent product instead of three separate screens.

### ▸ Slide 15: Move more, together

Everything I've shown you so far is a solo experience, and that's deliberate. But
there's one Pro feature worth calling out, because of how carefully we scoped it:
**social**.

You can bring a few friends in, see each other move, and start a session in sync.
That's it. The important part is what we *didn't* build. There's no leaderboard,
no streak-shaming, no turning a calm coach into a competition. It's light social
presence, the sense that someone else is moving too, without any of the pressure
that makes people quit in the first place.

It's the one place we let other people into the loop, and we let them in gently.

### ▸ Slide 16: Privacy by design

And this brings us to something we treat as a genuine feature, not a footnote:
privacy.

**All of your health data lives on your device.** The adaptive AI runs locally,
and nothing is sent to an external server, ever. The app doesn't even need a
network connection to learn.

Three points. Processing is **on-device**, so the signals are read and reasoned
about right there on the phone. There's **no server round-trip**, so your health
data never leaves. And we state that **plainly**, in the product's own voice.

In a category built entirely on sensitive health signals, being on-device by
default isn't just the ethical choice. It's a real competitive edge, and for us
it's built into the architecture rather than promised in a policy page.

### ▸ Slide 17: Closing

So let me bring us back to where we started.

Most fitness apps lose people at the decision, not at the effort. PulseCoach
removes that planning tax entirely, so staying consistent stops depending on
willpower and starts depending on simply opening the app.

And we want to be clear that this isn't a concept. It's a feature-complete,
working application, with an on-device adaptive engine, a full design system, and
around fourteen hundred automated tests behind it, all passing.

*Move more. Decide less.* That's PulseCoach.

Thank you. We'd be happy to take your questions.
