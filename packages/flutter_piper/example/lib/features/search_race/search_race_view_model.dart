import 'dart:async';

import 'package:flutter_piper/flutter_piper.dart';

import 'search_race_repository.dart';

enum SearchRaceEventKind {
  request,
  cancelled,
  success,
  stale,
  lateArrival,
  lifecycle,
}

final class SearchRaceEvent {
  final String message;
  final SearchRaceEventKind kind;

  const SearchRaceEvent(this.message, this.kind);
}

class SearchRaceViewModel extends ViewModel {
  SearchRaceViewModel(this._repository);

  static const typingInterval = Duration(milliseconds: 90);
  static const _typedWord = 'flutter';

  final SearchRaceRepository _repository;

  /// The text visible in the search box, typed character by character.
  late final query = state('');

  /// The query whose request is currently in flight.
  late final submittedQuery = state('');

  /// False runs the race with last-response-wins, the bug Piper prevents.
  late final piperEnabled = state(false);

  late final results = asyncState<List<SearchHit>>();

  /// True when the visible results answer an older query than the one typed.
  late final resultsAreStale = state(false);

  late final events = state<List<SearchRaceEvent>>(const []);
  late final cancelledRequests = state(0);
  late final staleOverwrites = state(0);
  late final hasRun = state(false);

  Task<void>? _activeSearch;
  Task<void>? _race;
  int _session = 0;
  int _request = 0;

  void setPiperEnabled(bool enabled) {
    reset();
    piperEnabled.value = enabled;
  }

  void runRace() {
    reset();
    hasRun.value = true;
    _race = launch((cancellation) async {
      query.value = 'f';
      beginSearch('f');
      for (var length = 2; length <= _typedWord.length; length++) {
        await cancellation.wait(typingInterval.delay);
        query.value = _typedWord.substring(0, length);
      }
      beginSearch(_typedWord);
    });
  }

  void beginSearch(String nextQuery) {
    final session = _session;
    final request = ++_request;
    query.value = nextQuery;
    submittedQuery.value = nextQuery;
    results.setLoading();
    resultsAreStale.value = false;
    _record('Request for “$nextQuery” sent', SearchRaceEventKind.request);
    final response = _repository.search(nextQuery);
    if (piperEnabled.value) {
      _searchWithPiper(nextQuery, response, session, request);
    } else {
      _searchWithoutPiper(nextQuery, response, session, request);
    }
  }

  void _searchWithPiper(
    String nextQuery,
    Future<List<SearchHit>> response,
    int session,
    int request,
  ) {
    final previous = _activeSearch;
    if (previous?.isActive ?? false) previous!.cancel();
    _activeSearch = launch((cancellation) async {
      try {
        final value = await cancellation.wait(response);
        if (session != _session || request != _request) return;
        results.setData(value);
        resultsAreStale.value = false;
        _record('Results for “$nextQuery” shown', SearchRaceEventKind.success);
      } on TaskCancelledException {
        if (session != _session) return;
        cancelledRequests.update((count) => count + 1);
        _record(
          'Task for “$nextQuery” cancelled — its response will be ignored',
          SearchRaceEventKind.cancelled,
        );
        unawaited(
          response.then((_) {
            if (session != _session) return;
            _record(
              'Late “$nextQuery” response arrived — discarded',
              SearchRaceEventKind.lateArrival,
            );
          }, onError: (_) {}),
        );
      }
    });
  }

  /// Deliberately naive: no cancellation, so whichever response lands last
  /// wins — even when it answers a query the user has already moved past.
  void _searchWithoutPiper(
    String nextQuery,
    Future<List<SearchHit>> response,
    int session,
    int request,
  ) {
    _activeSearch = launch((_) async {
      final value = await response;
      if (session != _session) return;
      results.setData(value);
      if (request != _request) {
        resultsAreStale.value = true;
        staleOverwrites.update((count) => count + 1);
        _record(
          'Late “$nextQuery” response arrived — overwrote the newer results',
          SearchRaceEventKind.stale,
        );
      } else {
        resultsAreStale.value = false;
        _record('Results for “$nextQuery” shown', SearchRaceEventKind.success);
      }
    });
  }

  void reset() {
    _session++;
    _request++;
    _race?.cancel();
    _activeSearch?.cancel();
    query.value = '';
    submittedQuery.value = '';
    results.setEmpty();
    resultsAreStale.value = false;
    events.value = const [];
    cancelledRequests.value = 0;
    staleOverwrites.value = 0;
    hasRun.value = false;
  }

  void _record(String message, SearchRaceEventKind kind) {
    events.value = List.unmodifiable([
      ...events.value,
      SearchRaceEvent(message, kind),
    ]);
  }

  @override
  void dispose() {
    final active = _activeSearch?.isActive ?? false;
    if (active) {
      _record(
        'ViewModel disposed — active task cancelled',
        SearchRaceEventKind.lifecycle,
      );
    }
    _session++;
    super.dispose();
  }
}

extension on Duration {
  Future<void> get delay => Future<void>.delayed(this);
}
