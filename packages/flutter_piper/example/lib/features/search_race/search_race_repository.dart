import 'dart:async';

final class SearchHit {
  final String title;
  final String detail;

  const SearchHit(this.title, this.detail);
}

abstract interface class SearchRaceRepository {
  Future<List<SearchHit>> search(String query);
}

final class DemoSearchRaceRepository implements SearchRaceRepository {
  const DemoSearchRaceRepository();

  @override
  Future<List<SearchHit>> search(String query) async {
    await Future<void>.delayed(_delayFor(query));
    return _resultsFor(query);
  }

  Duration _delayFor(String query) => switch (query) {
    'f' => const Duration(milliseconds: 1200),
    'flutter' => const Duration(milliseconds: 280),
    _ => const Duration(milliseconds: 500),
  };

  List<SearchHit> _resultsFor(String query) => switch (query) {
    'f' => const [
      SearchHit('Firebase', 'The slow, stale response'),
      SearchHit('Fuchsia', 'This should not replace newer results'),
    ],
    'flutter' => const [
      SearchHit('Flutter', 'Build beautiful apps from a single codebase'),
      SearchHit('flutter_piper', 'Lifecycle-owned ViewModels for Flutter'),
      SearchHit('flutter_test', 'Test Flutter widgets and interactions'),
    ],
    _ => [SearchHit(query, 'A simulated search result')],
  };
}
