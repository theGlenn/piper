# Piper Search Race

A runnable, visual proof of Piper's lifecycle-owned async work.

Press **Run search race** to start a deliberately slow search for `f`, then a
faster search for `flutter`. The first task is cancelled before it can replace
the correct result, and the request timeline shows why.

## What it demonstrates

- `ViewModelScope` owns the screen's `SearchRaceViewModel`
- `Watch` rebuilds the interface from state read in one place
- `TaskCancellationToken.wait()` prevents the slow response from writing
- A ViewModel disposal cancels active work automatically
- Constructor injection keeps the simulated repository explicit

The latency is deterministic: `f` takes 1.2 seconds and `flutter` takes 280
milliseconds, so the demo behaves reliably in a recording or on the web.

## Running

```bash
flutter run
```
