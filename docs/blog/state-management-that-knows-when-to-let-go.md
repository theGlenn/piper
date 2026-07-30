---
title: State management that knows when to let go
description: Why build another Flutter state library when Riverpod and Bloc exist? Because they manage state, and the bugs live in the async work that produces state. Piper gives that work an owner.
---

# State management that knows when to let go

Flutter does not need another state management library. That was my position
too, so let me answer the question you are already asking — *why build this
when Riverpod and Bloc exist?* — before asking for any of your time.

They manage state, and they manage it well. The bugs that kept reaching my
production apps were never in the state. They were in the **async work that
produces state** — the requests, streams, and timers that outlive the
keystroke, the screen, or the session that started them. In Flutter, that work
has no owner by default. Every library leaves you to assemble its lifetime by
hand, each with different tools.

Piper is a state management library built around one rule: **the thing that
owns the state owns the work that produces it, and when the owner goes, the
work goes.** State, async tasks, stream subscriptions, and derived values live
in plain Dart ViewModels — the pattern that has quietly worked on Android and
iOS for a decade — and when the ViewModel is disposed or a newer request takes
over, the old work is cancelled before it can touch your state.

Piper owns lifetime, and deliberately nothing else. Not your dependency
injection, not your widget base classes, not your architecture.

That is the whole pitch. The rest of this article is the problem in concrete
form, what the existing libraries actually offer for it, and what changes when
lifetime is the default instead of a patch.

## The problem: async work has no owner

Here is the smallest version of it. A search screen. The user types `f`, then
finishes typing `flutter`. Two requests are in flight. The `f` query matched
half the database, so it is slow; `flutter` is narrow and comes back first. You
render the right results — then the `f` response lands, and your state holder,
which has no idea it is late, happily accepts it. The user asked for `flutter`
and is looking at results for `f`.

You can [watch this happen](https://glennso.dev/piper/demo/) in a live demo
with a toggle that turns the protection off and on.

Every Flutter developer has written the patches for this, because the naive
code looks correct:

```dart
Future<void> onQueryChanged(String query) async {
  setState(() => _loading = true);
  final data = await repo.search(query);
  setState(() {
    _results = data;
    _loading = false;
  });
}
```

The patches arrive in a familiar order: a `mounted` check, for when the screen
is gone by the time the response lands. A request ID counter, for when the
screen is still there but the response is obsolete. A debounce `Timer?`, so a
request does not fire per keystroke — held in a field, cancelled in `dispose`.
A `CancelToken`, threaded through the repository and also cancelled in
`dispose`.

Now one search box owns a boolean, a list, an int, a `Timer?`, a
`CancelToken?`, and a `dispose` method that must remember all of them — and
none of it can be unit tested without pumping a widget tree. Add a second async
operation to the screen and it doubles.

Notice what every patch has in common: each one is a hand-written answer to the
same question — *does this work still matter?* — asked at a different call
site. `mounted` asks it. The request ID asks it. `dispose` asks it a third
time. The work has no owner, so every consumer must independently re-derive
whether it is still wanted.

## Why not Riverpod or Bloc?

The fair answer is: for the lifetime problem, they can each get you there. In
**Riverpod**, `autoDispose` tears state down when the last listener leaves,
`ref.onDispose` lets you cancel a token when a provider is rebuilt, and a
refreshed provider discards the previous future's result. In **Bloc**, the
`bloc_concurrency` package's `restartable()` transformer gives a handler
last-event-wins, and the framework guards against `emit` after a handler
completes. Both libraries are mature, their trade-offs are deliberate, and
many teams ship excellent apps with them.

But in both, cleanup is per-site, opt-in knowledge. The default is that async
work runs to completion and writes whatever it likes; safety is something you
add at each place you remember to, with a mechanism you had to already know
existed. After years of watching the same patches get rewritten in code
review — mine included — I wanted the opposite default. Coming from Android, I
knew what it felt like: a `ViewModel` with a `viewModelScope`, where work is
structured under an owner and dies with it, and where *leaking* work is what
takes effort. Flutter did not have that as a default.

That is half of why Piper exists. The other half is a disagreement not about
capability but about **scope** — about how much of your app a state library
should own. Nothing below is a defect in Riverpod or Bloc; each is a price
their designs ask you to pay, and I no longer wanted to pay it.

## How much of your app should a state library own?

**Not your widgets.** Observing state should not change what your widgets
*are*. I did not want to trade `StatelessWidget` for a library base class, or
wrap every screen in builder widgets, before a single value could reach the
screen. In Piper, a plain `StatelessWidget` reads a ViewModel and rebuilds
exactly where it watches. The UI layer stays the Flutter you already know.

**Not your dependency injection.** Riverpod is, by design, a dependency
injection system and a state system fused into one. That fusion is its power —
and its price: adopt one half and you have adopted the other, every object
worth testing lives in the provider graph, and swapping a dependency means
overriding it there. Dart already ships a dependency injection mechanism: the
constructor. A Piper ViewModel takes its repository as a parameter, and in a
test the fake goes in the same door. Nothing to override, because nothing was
hidden.

**Not your architecture.** Separating presentation from business logic is a
discipline, not a feature a package can install. When a library asks a counter
to declare event classes before it can increment, the machinery starts to
stand in for the principle — and newcomers learn the machinery instead of the
principle. A library's job is to make the disciplined path the easiest path
and then get out of the way. Piper gives you a plain class with visible
dependencies and owned lifetimes; the architecture is yours.

**Not more of your head than the problem deserves.** State management is a
small idea: values change, the UI reacts, work stops when it stops mattering.
The solution should be roughly the size of the idea — no provider taxonomy to
choose from, no annotations, no code generation, no event vocabulary. My rough
measure of a library's conceptual weight is how much documentation it takes to
hold all of it. Piper's docs are short on purpose: there are only a few
primitives, and they are all the same rule wearing different clothes.

## The solution: lifetime follows ownership

In Piper, the ViewModel owns its state and every piece of work that produces
it. Here is the entire search feature — debounce, cancellation, staleness, and
cleanup included:

```dart
class SearchViewModel extends ViewModel {
  SearchViewModel(this._repo);

  final SearchRepository _repo;

  late final query = state('');
  late final results = asyncState<List<SearchResult>>();

  Task<void>? _searchTask;

  void onQueryChanged(String value) {
    query.value = value;
    _searchTask?.cancel();

    if (value.isEmpty) {
      results.setEmpty();
      return;
    }

    results.setLoading();
    _searchTask = launch((cancellation) async {
      await cancellation.wait(
        Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final data = await cancellation.wait(_repo.search(value));
      results.setData(data);
    });
  }
}
```

Three things carry the weight here.

**Cancelling unwinds the body.** When a newer keystroke calls `cancel()`, the
task stops at its next `cancellation.wait`. The statements after it never run —
`results.setData(data)` is not a line you guard, it is a line that cannot be
reached with stale data. The debounce is the same mechanism: because the delay
is awaited through `cancellation.wait`, a new keystroke interrupts it instead
of letting it expire into a pointless request.

**There is no `dispose` to write.** Disposing the ViewModel disposes its task
scope, which cancels everything still running in it. Navigate away mid-search
and the request stops mattering because its owner stopped existing. No
`mounted` check appears in this file, because no widget appears in this file.

**It is one rule, applied everywhere.** A stream subscription is work with a
lifetime, so `bind(repo.userStream)` ties it to the ViewModel and it is
cancelled on dispose — no `StreamSubscription?` field, no teardown to
remember. Derived state is work with a lifetime, so `computed()` tracks what it
reads and dies with its owner — no dependency array to keep in sync. These are
not separate features to learn. They are the ownership rule showing up three
times.

## The value: what you stop writing

Count what is absent from that ViewModel: no `mounted` check, no request ID, no
`Timer?` field, no `CancelToken?` field, no `dispose` override, no `autoDispose`
annotation, no concurrency transformer, no generated files. The bookkeeping did
not move somewhere else — the question it existed to answer ("does this still
matter?") is answered once, by ownership, instead of at every call site.

And because the ViewModel is plain Dart with constructor-injected dependencies,
the stale-result race — the bug that started this article — is a regular
`test()`:

```dart
test('the late response cannot win', () async {
  final repo = FakeSearchRepository();
  final vm = SearchViewModel(repo);

  vm.onQueryChanged('f');
  vm.onQueryChanged('flutter'); // cancels the 'f' task

  await repo.completeSearch('flutter', flutterResults);
  await repo.completeSearch('f', staleResults); // arrives late

  expect(vm.results.dataOrNull, flutterResults);
});
```

No widget pumping, no test container, no override graph — the fake went in
through the constructor. If your current architecture makes that test awkward
to write, the lifetime of your async work is probably still owned by a widget.

## The honest limits

Cancellation in Dart is cooperative, and any library claiming otherwise is
selling you something. Two things to know before adopting this:

**`cancellation.wait` is load-bearing.** A task body that never consults its
token runs to completion. Wrap your async boundaries, or call
`cancellation.throwIfCancelled()` before a side effect.

**Cancelling the task is not aborting the socket.** By default the underlying
HTTP request still completes; the guarantee is that its result cannot write to
your state. If your client exposes an abort API, `cancellation.onCancel` lets
you wire it up so the request is genuinely torn down. Precisely: correctness of
your state, always; bytes on the wire, only if you ask.

## Try it, and tell me where the model breaks

The [Search Race demo](https://glennso.dev/piper/demo/) runs the race
deterministically in your browser, with the unprotected mode one toggle away.
`piper_state` is on [pub.dev](https://pub.dev/packages/piper_state), the
Flutter bindings are
[`flutter_piper`](https://pub.dev/packages/flutter_piper), and the source is on
[GitHub](https://github.com/theGlenn/piper).

What I want feedback on is the ownership model, not the API surface. Where does
"lifetime follows ownership" stop being the right answer? Work that should
outlive the screen that started it — an upload that continues across
navigation, a sync that must finish — is the obvious pressure point, and the
honest answer today is that such work does not belong to a screen's ViewModel
at all. If you have hit a case that sits uncomfortably between the two, I want
to hear about it.
