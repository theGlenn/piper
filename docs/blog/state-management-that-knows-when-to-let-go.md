---
title: State management that knows when to let go
description: Riverpod and Bloc manage state well. Piper focuses on the async work that produces it, giving requests, streams, and timers an owner and a lifetime.
---

# State management that knows when to let go

Riverpod and Bloc already manage state well, so for years I thought Flutter did
not need another state management library.

Yet the same questions kept coming back, in codebase after codebase, with or
without a state library. Why does showing a search result need a `mounted`
check? Why can a response the user has stopped caring about overwrite the one
they asked for? Why does every `dispose` read like a checklist of everything
the screen ever started? Why does testing a screen's logic mean pumping a
widget tree instead of calling a method?

Four questions, one answer. The bugs that kept reaching my production apps
were never in the state itself. They came from the async work that *produces*
state: requests, streams, and timers that outlive the keystroke, the screen,
or the session that started them. In Flutter, that work has no owner by
default. Its lifetime gets assembled by hand, at each call site, by whoever
remembers. The libraries that managed my state so well still left its lifetime
to me.

Piper is a state management library built around one rule: **the thing that
owns the state owns the work that produces it, and when the owner goes, the
work goes.** State, async tasks, stream subscriptions, and derived values live
in plain Dart ViewModels, a pattern Android and MVVM codebases have relied on
for years. When the ViewModel is disposed or a newer request takes over, the
old work is cancelled before it can touch your state.

Piper owns lifetime. Dependency injection, widget base classes, and
architecture stay yours.

Piper exists for two reasons. One is that recurring bug: async work with no
owner, a problem Android solved years ago with `viewModelScope` and that
Flutter's libraries each patch with their own added machinery. The other is an
opinion about how much of your app a state library should own. The rest of
this article is the bug, the fix, and the opinion, in that order.

## The problem: async work has no owner

You have seen the bug this article is about, even if you never filed it. A
search screen: results appear, then get replaced by an answer to a question
the user has stopped asking, because a slow, stale response landed after a
newer, correct one. The [live demo](https://glennso.dev/piper/demo/)
reproduces it on demand, with a toggle that turns the protection off and on.

I had written the patches for it more than once, because the naive code looks
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

## Riverpod and Bloc can do this

In Riverpod, `autoDispose` tears state down when the last listener leaves, and
`ref.onDispose` gives you a hook to cancel work when a provider is rebuilt. In
Bloc, the `bloc_concurrency` package's `restartable()` transformer processes
only the latest event and cancels previous event handlers. Both work, and
teams ship excellent apps with them.

The difference is where the safety lives. In each case it is a mechanism you
opt into, per provider or per handler, after you have learned that it exists.
On Android, a `ViewModel`'s `viewModelScope` taught me the opposite
arrangement: work lives under an owner and dies with it, by default, and
*leaking* work is what takes effort. Flutter did not have that default, so I
built it.

## Lifetime follows ownership

In Piper, the ViewModel owns its state and every piece of work that produces
it. Here is the lifetime-management path of a search feature, with debounce,
cancellation, staleness, and cleanup in one place:

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

The same ownership rule applies everywhere. `bind(repo.userStream, initial:
null)` ties a stream subscription to the ViewModel and cancels it on dispose,
removing the `StreamSubscription?` field and manual teardown. `computed()`
tracks the state it reads and dies with its owner, so there is no dependency
array to keep in sync. Ownership governs tasks, streams, and derived state.

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

## How much should a state library own?

That is the mechanism. The opinion behind it is about scope: a state library
should give you control and clarity, and take as little of your app as
possible in exchange.

**Your widgets stay widgets.** A plain `StatelessWidget` reads a ViewModel and
rebuilds exactly where it watches. Values reach the screen without a library
base class or a builder wrapping every screen. The UI layer stays the Flutter
you already know.

**Your dependencies stay visible.** Dart already ships a dependency injection
mechanism: the constructor. A ViewModel takes its repository as a parameter,
and in a test the fake goes in through the same door. There is nothing to
override because nothing was hidden. If you prefer a DI framework, Piper does
not compete with it; it just does not require one.

**Your architecture stays yours.** Separating presentation from business logic
is a discipline, not a feature a package can install. Piper's contribution is
to make the disciplined path the easiest one, a plain class with visible
dependencies and owned lifetimes, and then get out of the way. Nothing names
your layers or defines an event vocabulary for you. (Bloc's own
[`Cubit`](https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc) is a nod in
the same direction, and its docs recommend starting there.)

**Your head stays clear.** State management is a small idea: values change,
the UI reacts, work stops when it stops mattering. Piper keeps its conceptual
weight close to the size of that idea: a few primitives, each applying the
same ownership rule to a different kind of work, and nothing to generate. My
rough measure of a library's weight is how much documentation it takes to hold
all of it; Piper's docs are short on purpose.

Minimalism has a price, though, and it is fair to name it.

## The limits

Cancellation in Dart is cooperative, and any library claiming otherwise is
selling you something. So it is worth being precise about which half of the
safety is automatic and which half is yours.

Disposal is structural. When a ViewModel goes, its tasks, stream bindings, and
derived state go with it. You never write that, and you cannot forget it.

Interruption is cooperative. A task body that never consults its token runs to
completion: `cancellation.wait` is load-bearing, and skipping it at an async
boundary brings the stale-write risk back.
`cancellation.throwIfCancelled()` covers the spots between awaits. In exchange
you get one mechanism, applied the same way everywhere, instead of four
unrelated patches. You still have to apply it.

Cancelling the task is also not aborting the HTTP request. By default the
response still arrives; it just cannot write to your state. If your client
exposes an abort API, `cancellation.onCancel` lets you tear the request down
too. Piper guarantees correct state; stopping bytes on the wire requires
client integration.

That is the deal: the library owns lifetime; you keep the control, and the
small responsibilities that come with it.

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
