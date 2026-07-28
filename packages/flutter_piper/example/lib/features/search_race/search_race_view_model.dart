import 'dart:async';

import 'package:flutter_piper/flutter_piper.dart';

import 'search_race_repository.dart';

enum SearchRaceEventKind { request, cancelled, success, lifecycle }

final class SearchRaceEvent {
  final String message;
  final SearchRaceEventKind kind;

  const SearchRaceEvent(this.message, this.kind);
}

class SearchRaceViewModel extends ViewModel {
  SearchRaceViewModel(this._repository);

  final SearchRaceRepository _repository;

  late final query = state('');
  late final results = asyncState<List<SearchHit>>();
  late final events = state<List<SearchRaceEvent>>(const []);
  late final cancelledRequests = state(0);
  late final hasRun = state(false);

  Task<void>? _activeSearch;
  Task<void>? _race;
  int _session = 0;
  int _request = 0;

  void runRace() {
    reset();
    hasRun.value = true;
    beginSearch('f');
    _race = launch((cancellation) async {
      await cancellation.wait(const Duration(milliseconds: 220).delay);
      beginSearch('flutter');
    });
  }

  void beginSearch(String nextQuery) {
    final previous = _activeSearch;
    if (previous?.isActive ?? false) previous!.cancel();

    final session = _session;
    final request = ++_request;
    query.value = nextQuery;
    results.setLoading();
    _record('Task for “$nextQuery” started', SearchRaceEventKind.request);
    _activeSearch = launch((cancellation) async {
      try {
        final value = await cancellation.wait(_repository.search(nextQuery));
        if (session != _session || request != _request) return;
        results.setData(value);
        _record(
          'Results for “$nextQuery” committed',
          SearchRaceEventKind.success,
        );
      } on TaskCancelledException {
        if (session != _session) return;
        cancelledRequests.update((count) => count + 1);
        _record(
          'Task for “$nextQuery” cancelled',
          SearchRaceEventKind.cancelled,
        );
      }
    });
  }

  void reset() {
    _session++;
    _request++;
    _race?.cancel();
    _activeSearch?.cancel();
    query.value = '';
    results.setEmpty();
    events.value = const [];
    cancelledRequests.value = 0;
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
