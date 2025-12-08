# Search with Cancellation

Debounce and cancel stale requests without RxDart.

## ViewModel

```dart
class SearchViewModel extends ViewModel {
  final SearchRepository _repo;

  SearchViewModel(this._repo);

  late final query = state('');
  late final results = asyncState<List<SearchResult>>();

  Task<void>? _searchTask;

  void onQueryChanged(String value) {
    query.value = value;

    // Cancel previous search
    _searchTask?.cancel();

    if (value.isEmpty) {
      results.setEmpty();
      return;
    }

    results.setLoading();

    _searchTask = launch(() async {
      // Debounce
      await Future.delayed(const Duration(milliseconds: 300));

      final data = await _repo.search(value);
      results.setData(data);
    });
  }
}
```

## Widget

```dart
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: vm.onQueryChanged,
          decoration: InputDecoration(hintText: 'Search...'),
        ),
      ),
      body: vm.results.build(
        (state) => switch (state) {
          AsyncEmpty() => Center(child: Text('Start typing to search')),
          AsyncLoading() => Center(child: CircularProgressIndicator()),
          AsyncError(:final message) => Center(child: Text('Error: $message')),
          AsyncData(:final data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(data[i].title),
              subtitle: Text(data[i].description),
            ),
          ),
        },
      ),
    );
  }
}
```

## What's happening

1. **Debounce** — `await Future.delayed()` before searching
2. **Cancel** — `_searchTask?.cancel()` stops stale requests from updating state
3. **No race conditions** — cancelled tasks don't call `setData()`
4. **Auto cleanup** — task cancelled if ViewModel is disposed mid-search
