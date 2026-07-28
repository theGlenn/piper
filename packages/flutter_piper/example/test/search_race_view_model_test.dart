import 'dart:async';

import 'package:example/features/search_race/search_race_repository.dart';
import 'package:example/features/search_race/search_race_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piper_state/piper_state.dart';

void main() {
  test('a cancelled slow search cannot overwrite newer results', () async {
    final repository = _ControlledSearchRepository();
    final viewModel = SearchRaceViewModel(repository);
    addTearDown(viewModel.dispose);

    viewModel.beginSearch('f');
    viewModel.beginSearch('flutter');
    await Future<void>.delayed(Duration.zero);

    repository.complete('flutter', const [SearchHit('Flutter', 'Fast result')]);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.results.value, isA<AsyncData<List<SearchHit>>>());
    expect(viewModel.results.dataOrNull!.single.title, 'Flutter');
    expect(viewModel.cancelledRequests.value, 1);

    repository.complete('f', const [SearchHit('F', 'Slow result')]);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.results.dataOrNull!.single.title, 'Flutter');
    expect(
      viewModel.events.value.map((event) => event.message),
      contains('Task for “f” cancelled'),
    );
  });

  test('disposing the ViewModel cancels its active request', () async {
    final repository = _ControlledSearchRepository();
    final viewModel = SearchRaceViewModel(repository);

    viewModel.beginSearch('f');
    viewModel.dispose();
    repository.complete('f', const [SearchHit('F', 'Slow result')]);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.results.dataOrNull, isNull);
    expect(
      viewModel.events.value.map((event) => event.message),
      contains('ViewModel disposed — active task cancelled'),
    );
  });
}

class _ControlledSearchRepository implements SearchRaceRepository {
  final _requests = <String, Completer<List<SearchHit>>>{};

  @override
  Future<List<SearchHit>> search(String query) =>
      _requests.putIfAbsent(query, Completer<List<SearchHit>>.new).future;

  void complete(String query, List<SearchHit> results) {
    _requests[query]!.complete(results);
  }
}
