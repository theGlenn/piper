import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

import 'search_race_repository.dart';
import 'search_race_view_model.dart';

// THESIS: The demo makes lifecycle-owned cancellation visible before a stale
// response can overwrite fresh search results.
// OWN-WORLD: A calm, high-contrast product lab: blue action surfaces, green
// completion signals, and a compact request timeline.
// STORY: Run the race, see “f” get cancelled, then see “flutter” win.
// FIRST VIEWPORT: The action and live result share the left; event proof sits
// beside it so the causal chain is readable in one glance.
// FORM: A responsive operating surface that keeps the interaction primary.
class SearchRacePage extends StatelessWidget {
  const SearchRacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope(
      create: [() => SearchRaceViewModel(const DemoSearchRaceRepository())],
      child: const _SearchRaceScreen(),
    );
  }
}

class _SearchRaceScreen extends StatelessWidget {
  const _SearchRaceScreen();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.vm<SearchRaceViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Watch((context) {
                final query = viewModel.query.value;
                final resultState = viewModel.results.value;
                final events = viewModel.events.value;
                final cancellations = viewModel.cancelledRequests.value;
                final hasRun = viewModel.hasRun.value;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 840;
                    final resultPanel = _ResultPanel(
                      query: query,
                      resultState: resultState,
                    );
                    final timelinePanel = _TimelinePanel(events: events);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Header(),
                          const SizedBox(height: 40),
                          Text(
                            'The slow request should lose.',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 640,
                            child: Text(
                              'Piper ties async work to its ViewModel. When a newer search starts, the old task cannot write a stale result.',
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SearchControls(
                            activeQuery: query,
                            hasRun: hasRun,
                            onRun: viewModel.runRace,
                            onReset: viewModel.reset,
                          ),
                          const SizedBox(height: 24),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: resultPanel),
                                const SizedBox(width: 24),
                                Expanded(flex: 5, child: timelinePanel),
                              ],
                            )
                          else ...[
                            resultPanel,
                            const SizedBox(height: 24),
                            timelinePanel,
                          ],
                          const SizedBox(height: 24),
                          _ProofStrip(
                            hasRun: hasRun,
                            cancellations: cancellations,
                          ),
                          const SizedBox(height: 32),
                          const _Explanation(),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          'Piper Search Race',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _SearchControls extends StatelessWidget {
  final String activeQuery;
  final bool hasRun;
  final VoidCallback onRun;
  final VoidCallback onReset;

  const _SearchControls({
    required this.activeQuery,
    required this.hasRun,
    required this.onRun,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final label = activeQuery.isEmpty ? 'Run search race' : activeQuery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Search query $label',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activeQuery.isEmpty
                        ? 'Ready to simulate a slow search'
                        : activeQuery,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Text('simulated latency'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run search race'),
            ),
            if (hasRun)
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            const _LatencyBadge(query: 'f', duration: '1.2s'),
            const _LatencyBadge(query: 'flutter', duration: '280ms'),
          ],
        ),
      ],
    );
  }
}

class _LatencyBadge extends StatelessWidget {
  final String query;
  final String duration;

  const _LatencyBadge({required this.query, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('“$query” · $duration'));
  }
}

class _ResultPanel extends StatelessWidget {
  final String query;
  final AsyncState<List<SearchHit>> resultState;

  const _ResultPanel({required this.query, required this.resultState});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Search results',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: resultState.when(
          empty: () => const _EmptyResult(),
          loading: () => _LoadingResult(query: query),
          error: (message) => Text(message),
          data: (results) => _SearchResults(results: results),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Text('Run the race to see the request timeline in action.'),
    );
  }
}

class _LoadingResult extends StatelessWidget {
  final String query;

  const _LoadingResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Searching for “$query”…'),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<SearchHit> results;

  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final result in results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(result.title),
            subtitle: Text(result.detail),
          ),
      ],
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final List<SearchRaceEvent> events;

  const _TimelinePanel({required this.events});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Request timeline',
      child: events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Start with “f”. Then Piper cancels it for “flutter”.',
              ),
            )
          : Column(
              children: [
                for (final event in events) _TimelineEvent(event: event),
              ],
            ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final SearchRaceEvent event;

  const _TimelineEvent({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = switch (event.kind) {
      SearchRaceEventKind.request => Theme.of(context).colorScheme.primary,
      SearchRaceEventKind.cancelled => Theme.of(context).colorScheme.error,
      SearchRaceEventKind.success => Colors.green.shade700,
      SearchRaceEventKind.lifecycle => Theme.of(context).colorScheme.tertiary,
    };
    final icon = switch (event.kind) {
      SearchRaceEventKind.request => Icons.play_circle_outline_rounded,
      SearchRaceEventKind.cancelled => Icons.cancel_outlined,
      SearchRaceEventKind.success => Icons.check_circle_outline_rounded,
      SearchRaceEventKind.lifecycle => Icons.auto_delete_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(event.message)),
        ],
      ),
    );
  }
}

class _ProofStrip extends StatelessWidget {
  final bool hasRun;
  final int cancellations;

  const _ProofStrip({required this.hasRun, required this.cancellations});

  @override
  Widget build(BuildContext context) {
    final message = hasRun
        ? '$cancellations stale request${cancellations == 1 ? '' : 's'} prevented'
        : 'Run the race to inspect the lifecycle';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 20),
        Text(
          'What this prevents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Without cancellation, the slow “f” response could arrive last and replace the correct “flutter” results. Piper interrupts the task body at its next cancellation-aware await, so that stale write never happens.',
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B1F33),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
