# Piper Search Race

A runnable, visual proof of Piper's lifecycle-owned async work — including
the bug it prevents.

Press **Run search race** and the demo types `flutter` for you: typing `f`
fires a deliberately slow request, finishing the word fires a fast one, and
the slow response comes back last.

- **Without Piper** (the default mode): last response wins. Watch the late
  `f` response overwrite the correct `flutter` results, marked `STALE` in red.
- **With Piper**: starting the newer search cancels the old task, so the late
  response arrives with nowhere to write. The request timeline shows the
  cancellation and the discarded arrival.

## What it demonstrates

- `ViewModelScope` owns the screen's `SearchRaceViewModel`
- `Watch` rebuilds the interface from state read in one place
- `TaskCancellationToken.wait()` prevents the slow response from writing
- The unprotected mode shows the last-response-wins bug for contrast
- A ViewModel disposal cancels active work automatically
- Constructor injection keeps the simulated repository explicit

The latency is deterministic: `f` takes 1.2 seconds and `flutter` takes 280
milliseconds, so the demo behaves reliably in a recording or on the web.

## Running

```bash
flutter run
```
