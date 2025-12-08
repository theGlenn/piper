# Search with Cancellation

Debounced search with automatic cancellation of stale requests.

## The Challenge

Search typically requires:
- Debouncing (don't search on every keystroke)
- Cancelling previous searches (avoid stale results)
- Loading states
- Error handling

Usually this means RxDart or complex stream manipulation. With Piper, it's straightforward.

## Repository

```dart
class SearchRepository {
  Future<List<SearchResult>> search(String query) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));

    // Simulate results
    return List.generate(
      10,
      (i) => SearchResult(
        id: '$i',
        title: 'Result for "$query" #$i',
        description: 'Description for result $i',
      ),
    );
  }
}

class SearchResult {
  final String id;
  final String title;
  final String description;

  SearchResult({
    required this.id,
    required this.title,
    required this.description,
  });
}
```

## ViewModel

```dart
import 'package:piper/piper.dart';

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
      // Debounce: wait before searching
      await Future.delayed(Duration(milliseconds: 300));

      // Fetch results
      final data = await _repo.search(value);

      // Update state (won't run if cancelled)
      results.setData(data);
    });
  }

  void clear() {
    _searchTask?.cancel();
    query.value = '';
    results.setEmpty();
  }
}
```

## Search Page

```dart
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: _SearchField(vm: vm),
        actions: [
          vm.query.build((q) => q.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: vm.clear,
              )
            : SizedBox.shrink(),
          ),
        ],
      ),
      body: vm.results.build(
        (state) => switch (state) {
          AsyncEmpty() => _EmptyState(),
          AsyncLoading() => _LoadingState(),
          AsyncError(:final message) => _ErrorState(message: message),
          AsyncData(:final data) => data.isEmpty
            ? _NoResults()
            : _ResultsList(results: data),
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final SearchViewModel vm;

  const _SearchField({required this.vm});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: vm.onQueryChanged,
      decoration: InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Start typing to search'),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Error: $message', style: TextStyle(color: Colors.red)),
    );
  }
}

class _NoResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No results found'));
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;

  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(result.title),
          subtitle: Text(result.description),
          onTap: () {
            // Handle result tap
          },
        );
      },
    );
  }
}
```

## Setup

```dart
void main() {
  final searchRepo = SearchRepository();

  runApp(
    ViewModelScope(
      create: [() => SearchViewModel(searchRepo)],
      child: MaterialApp(home: SearchPage()),
    ),
  );
}
```

## What's Happening

### Debounce

```dart
await Future.delayed(Duration(milliseconds: 300));
```

Simple. Just wait before making the request.

### Cancellation

```dart
_searchTask?.cancel();
_searchTask = launch(() async { ... });
```

Each new search cancels the previous one. If the user types "flutter":
1. "f" starts a search, waits 300ms
2. "fl" cancels "f", starts new search
3. "flu" cancels "fl", starts new search
4. ...
5. "flutter" finally completes

### No Stale Results

When a task is cancelled, its callbacks don't run:

```dart
results.setData(data);  // Won't execute if task was cancelled
```

This prevents the classic bug where a slow "f" search returns after a fast "flutter" search.

### Auto Cleanup

If the user navigates away mid-search, the ViewModel disposes and all tasks are cancelled. No "mounted" checks needed.

## Comparison

### With RxDart

```dart
_queryController.stream
  .debounceTime(Duration(milliseconds: 300))
  .distinct()
  .switchMap((query) => query.isEmpty
    ? Stream.value(<SearchResult>[])
    : _repo.search(query).asStream())
  .listen((results) => _results = results);
```

### With Piper

```dart
_searchTask?.cancel();
await Future.delayed(Duration(milliseconds: 300));
results.setData(await _repo.search(value));
```

Same behavior. Easier to read.
