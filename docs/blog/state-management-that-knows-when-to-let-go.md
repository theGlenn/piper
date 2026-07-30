---
title: State management that knows when to let go
description: Riverpod and Bloc manage state well. Piper focuses on the async work that produces it, giving requests, streams, and timers an owner and a lifetime.
---

# State management that knows when to let go

Riverpod and Bloc already manage state well, so for years I thought Flutter did
not need another state management library.

Yet the same questions kept bugging me, in codebase after codebase: why does
showing a search result need a `mounted` check? Why can a slow, stale response
overwrite the results the user actually asked for? Why does every `dispose`
read like a checklist of everything the screen ever started? And why does
testing any of this mean pumping a widget tree instead of calling a method?

Every one of those questions has the same answer. The bugs that kept reaching
my production apps were never in the state itself — they came from the async
work that *produces* state: requests, streams, and timers that outlived the
keystroke, the screen, or the session that started them. In Flutter, that work
has no owner by default, so its lifetime gets managed by hand inside widgets —
and logic that lives in a widget can only be tested through one. Each library
gives you different tools to assemble the lifetime yourself, and leaves the
assembling to you.

Piper is a state management library built around one rule: **the thing that
owns the state owns the work that produces it, and when the owner goes, the
work goes.** State, async tasks, stream subscriptions, and derived values live
in plain Dart ViewModels, a pattern used on Android and iOS for a decade. When
the ViewModel is disposed or a newer request takes over, the old work is
cancelled before it can touch your state.

Piper owns lifetime. Dependency injection, widget base classes, and
architecture stay yours.

## The problem: async work has no owner

Take a search screen where the user types `f`, then finishes typing `flutter`.
Two requests are in flight. The `f` query matched half the database, so it is
slow; `flutter` is narrow and comes back first. You render the right results.
Then the `f` response lands, and your state holder, which has no idea it is
late, happily accepts it. The user asked for `flutter` and is looking at
results for `f`.

You can [watch this happen](https://glennso.dev/piper/demo/) in a live demo
with a toggle that turns the protection off and on.

I had written the patches for this more than once, because the naive code looks
correct:

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

The patches arrive in a familiar order. First comes a `mounted` check for when
the screen is gone by the time the response lands. A request ID counter handles
obsolete responses while the screen is still there. Debouncing requires a
`Timer?` field, cancelled in `dispose`, so a request does not fire per
keystroke. A `CancelToken` gets threaded through the repository and also
cancelled in `dispose`.

Now one search box owns a boolean, a list, an int, a `Timer?`, a
`CancelToken?`, and a `dispose` method that must remember all of them. None of
it can be unit tested without pumping a widget tree. Add a second async
operation to the screen and it doubles.

Every patch makes a hand-written decision about whether the work still matters.
`mounted`, the request ID, and `dispose` each decide at a different call site.
With no owner, every consumer must independently re-derive whether the work is
still wanted.

## What Riverpod and Bloc offer

Riverpod and Bloc can each solve the lifetime problem. In Riverpod,
`autoDispose` tears state down when the last listener leaves,
`ref.onDispose` lets you cancel a token when a provider is rebuilt, and a
refreshed provider discards the previous future's result. In Bloc, the
`bloc_concurrency` package's `restartable()` transformer gives a handler
last-event-wins, and the framework guards against `emit` after a handler
completes. Both libraries are mature, and their trade-offs are deliberate.

In both, cleanup remains per-site, opt-in knowledge. Async work runs to
completion by default and writes whatever it likes. You add safety at each
place you remember, using a mechanism you had to know existed. After years of
watching the same patches get rewritten in code review, mine included, I wanted
safety by default.

On Android, a `ViewModel` has a `viewModelScope` where work lives under an
owner and dies with it. That structure makes leaking work take effort, and
Flutter did not offer it by default.

Piper also reflects my view on how much of an app a state library should own.
Riverpod and Bloc make deliberate trade-offs here; I no longer wanted to pay
their price.

## What Piper leaves alone

With Piper, observing state leaves your widgets as they are. A plain
`StatelessWidget` reads a ViewModel and rebuilds exactly where it watches. I
wanted values to reach the screen without trading `StatelessWidget` for a
library base class or wrapping every screen in builder widgets. The UI layer
stays the Flutter you already know.

Riverpod deliberately fuses dependency injection and state. Adopting either
half means every object worth testing lives in the provider graph, and swapping
a dependency means overriding it there. Dart already ships a dependency
injection mechanism: the constructor. A Piper ViewModel takes its repository
as a parameter, and in a test the fake goes in the same door. Constructor
injection keeps dependencies visible and removes the override step.

Separating presentation from business logic remains a discipline. When a
library asks a counter to declare event classes before it can increment, the
machinery starts to stand in for the principle. Newcomers learn the machinery
instead of the principle. Bloc also offers
[`Cubit`](https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc), which drops
the event vocabulary, and its docs recommend starting there if you are unsure
which to use. My comparison here is with `Bloc` proper. A library's job is to
make the disciplined path the easiest path and then get out of the way. Piper
gives you a plain class with visible dependencies and owned lifetimes; the
architecture is yours.

Piper keeps its conceptual weight close to the size of the problem. State
management is a small idea: values change, the UI reacts, work stops when it
stops mattering. A few primitives replace the provider taxonomy and the event
vocabulary, and there is nothing to generate. Riverpod's
[current guidance](https://riverpod.dev/docs/concepts/about_code_generation#should-i-use-code-generation)
recommends code generation only for projects that already use it, after Dart
stopped work on macros. That makes code generation a smaller distinction than
it was two years ago. My rough measure of a library's conceptual weight is how
much documentation it takes to hold all of it. Piper's docs are short on
purpose. The primitives are all the same rule wearing different clothes.

## Lifetime follows ownership

In Piper, the ViewModel owns its state and every piece of work that produces
it. Here is the entire search feature with debounce, cancellation, staleness,
and cleanup included:

```dart
class SearchViewModel extends ViewModel {
  SearchViewModel(
    this._repo, {
    this.debounce = const Duration(milliseconds: 300),
  });

  final SearchRepository _repo;
  final Duration debounce;

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
      await cancellation.wait(Future<void>.delayed(debounce));
      final data = await cancellation.wait(_repo.search(value));
      results.setData(data);
    });
  }
}
```

Three details carry the weight here.

Cancellation unwinds the body. When a newer keystroke calls `cancel()`, the
task stops at its next `cancellation.wait`, so the statements after it never
run. Stale data cannot reach `results.setData(data)`. The debounce uses the
same mechanism. Because the delay is awaited through `cancellation.wait`, a
new keystroke interrupts it instead of letting it expire into a pointless
request.

Disposal needs no override. Disposing the ViewModel cancels everything still
running in its task scope. Navigate away mid-search and the request stops
mattering because its owner stopped existing. This file needs no `mounted`
check because it contains no widget.

The same ownership rule applies everywhere. `bind(repo.userStream)` ties a
stream subscription to the ViewModel and cancels it on dispose, removing the
`StreamSubscription?` field and manual teardown. `computed()` tracks the state
it reads and dies with its owner, so there is no dependency array to keep in
sync. Ownership governs tasks, streams, and derived state.

## The value: what you stop writing

That ViewModel contains the state, one task, and the method that coordinates
them. Ownership replaces the `mounted` check, request ID, `Timer?` field,
`CancelToken?` field, `dispose` override, `autoDispose` annotation, concurrency
transformer, and generated files. It answers "does this still matter?" once
instead of at every call site.

Because the ViewModel is plain Dart with constructor-injected dependencies,
the stale-result race that started this article is a regular `test()`:

```dart
test('the late response cannot win', () async {
  final repo = ControlledSearchRepository();
  final vm = SearchViewModel(repo, debounce: Duration.zero);
  addTearDown(vm.dispose);

  vm.onQueryChanged('f');
  // debounce elapses, so the 'f' request is genuinely in flight
  await Future<void>.delayed(Duration.zero);

  vm.onQueryChanged('flutter'); // cancels the in-flight 'f' task
  await Future<void>.delayed(Duration.zero);

  repo.complete('flutter', flutterResults);
  await Future<void>.delayed(Duration.zero);
  expect(vm.results.dataOrNull, flutterResults);

  repo.complete('f', staleResults); // arrives late
  await Future<void>.delayed(Duration.zero);
  expect(vm.results.dataOrNull, flutterResults);
});

class ControlledSearchRepository implements SearchRepository {
  final _requests = <String, Completer<List<SearchResult>>>{};

  @override
  Future<List<SearchResult>> search(String query) =>
      _requests.putIfAbsent(query, Completer<List<SearchResult>>.new).future;

  void complete(String query, List<SearchResult> results) =>
      _requests[query]!.complete(results);
}
```

The constructor takes both the fake repository and a zero-length debounce, so
the test needs neither a clock nor a widget tree. The first
`Future.delayed(Duration.zero)` yields to the event loop, allowing the debounce
to elapse and the `'f'` request to start before `'flutter'` cancels it.
Completing `'f'` last reproduces the order that breaks naive code, but its
cancelled task can no longer write the stale result.

The article's snippets are compiled and run in
[`blog_search_view_model_test.dart`](https://github.com/theGlenn/piper/blob/main/packages/flutter_piper/example/test/blog_search_view_model_test.dart).
The demo has a separate
[`search_race_view_model_test.dart`](https://github.com/theGlenn/piper/blob/main/packages/flutter_piper/example/test/search_race_view_model_test.dart)
that forces the race with cancellation enabled and disabled. The stale response
loses in the protected case and overwrites the newer results in the unprotected
case. That is the failure mode I would want under test before trusting someone
else's claim. If your architecture makes those tests awkward to write, the
lifetime of your async work is probably still owned by a widget.

## The limits

Cancellation in Dart is cooperative, and any library claiming otherwise is
selling you something.

`cancellation.wait` is load-bearing. A task body that never consults its token
runs to completion. Wrap your async boundaries, or call
`cancellation.throwIfCancelled()` before a side effect.

By default, cancelling the task prevents state writes while the underlying HTTP
request continues. If your client exposes an abort API,
`cancellation.onCancel` lets you tear down the request itself. Piper guarantees
correct state. Stopping bytes on the wire requires client integration.

## Try it, and tell me where the model breaks

The [Search Race demo](https://glennso.dev/piper/demo/) runs the race
deterministically in your browser, with the unprotected mode one toggle away.
`piper_state` is on [pub.dev](https://pub.dev/packages/piper_state), the
Flutter bindings are
[`flutter_piper`](https://pub.dev/packages/flutter_piper), and the source is on
[GitHub](https://github.com/theGlenn/piper).

I want feedback on the ownership model, especially where "lifetime follows
ownership" stops being the right answer. Work that should outlive the screen
that started it is the obvious pressure point: an upload that continues across
navigation, or a sync that must finish. Such work needs an owner above the
screen's ViewModel. If you have hit a case that sits uncomfortably between the
two, I want to hear about it.
