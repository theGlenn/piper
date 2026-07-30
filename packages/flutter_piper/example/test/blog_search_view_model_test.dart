// Verifies the code published in
// docs/blog/state-management-that-knows-when-to-let-go.md compiles and passes.
// Keep this file in sync with the article's snippets.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:piper_state/piper_state.dart';

class SearchResult {
  const SearchResult(this.title);
  final String title;
}

abstract class SearchRepository {
  Future<List<SearchResult>> search(String query);
}

// --- article snippet: the ViewModel ---------------------------------------

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

// --- article snippet: the test --------------------------------------------

void main() {
  const flutterResults = [SearchResult('Flutter')];
  const staleResults = [SearchResult('F')];

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
}

class ControlledSearchRepository implements SearchRepository {
  final _requests = <String, Completer<List<SearchResult>>>{};

  @override
  Future<List<SearchResult>> search(String query) =>
      _requests.putIfAbsent(query, Completer<List<SearchResult>>.new).future;

  void complete(String query, List<SearchResult> results) =>
      _requests[query]!.complete(results);
}
