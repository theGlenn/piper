import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

import 'search_race_repository.dart';
import 'search_race_view_model.dart';

// THESIS: The demo makes the stale-response bug happen on screen, then makes
// lifecycle-owned cancellation visibly prevent it.
// OWN-WORLD: A calm, high-contrast product lab: blue action surfaces, green
// completion signals, red only for the stale overwrite, and a compact
// request timeline.
// STORY: Run the race without Piper and watch the wrong results win; switch
// Piper on and watch the late response get discarded.
// FIRST VIEWPORT: The question, the mode toggle, and the live result share
// the left; event proof sits beside it so the causal chain is readable in
// one glance.
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
                final submittedQuery = viewModel.submittedQuery.value;
                final piperEnabled = viewModel.piperEnabled.value;
                final resultState = viewModel.results.value;
                final resultsAreStale = viewModel.resultsAreStale.value;
                final events = viewModel.events.value;
                final cancellations = viewModel.cancelledRequests.value;
                final staleOverwrites = viewModel.staleOverwrites.value;
                final hasRun = viewModel.hasRun.value;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 840;
                    final resultPanel = _ResultPanel(
                      submittedQuery: submittedQuery,
                      resultState: resultState,
                      isStale: resultsAreStale,
                    );
                    final timelinePanel = _TimelinePanel(events: events);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Header(),
                          const SizedBox(height: 40),
                          Text(
                            'You typed “flutter”. The “f” response arrives last.',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 640,
                            child: Text(
                              'Typing “f” starts a slow request. Finishing the '
                              'word starts a fast one. Responses come back in '
                              'the wrong order — run the race in both modes '
                              'and watch which results end up on screen.',
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ModeToggle(
                            piperEnabled: piperEnabled,
                            onChanged: viewModel.setPiperEnabled,
                          ),
                          const SizedBox(height: 16),
                          _SearchControls(
                            typedQuery: query,
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
                            piperEnabled: piperEnabled,
                            cancellations: cancellations,
                            staleOverwrites: staleOverwrites,
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

class _ModeToggle extends StatelessWidget {
  final bool piperEnabled;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.piperEnabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.warning_amber_rounded),
          label: Text('Without Piper'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.shield_outlined),
          label: Text('With Piper'),
        ),
      ],
      selected: {piperEnabled},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SearchControls extends StatelessWidget {
  final String typedQuery;
  final bool hasRun;
  final VoidCallback onRun;
  final VoidCallback onReset;

  const _SearchControls({
    required this.typedQuery,
    required this.hasRun,
    required this.onRun,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final label = typedQuery.isEmpty ? 'Run search race' : typedQuery;
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
                    typedQuery.isEmpty
                        ? 'Press play — the demo types “flutter” for you'
                        : typedQuery,
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
            const _LatencyBadge(query: 'f', duration: 'slow · 1.2s'),
            const _LatencyBadge(query: 'flutter', duration: 'fast · 280ms'),
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
  final String submittedQuery;
  final AsyncState<List<SearchHit>> resultState;
  final bool isStale;

  const _ResultPanel({
    required this.submittedQuery,
    required this.resultState,
    required this.isStale,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Search results',
      trailing: isStale ? const _StaleBadge() : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: resultState.when(
          empty: () => const _EmptyResult(),
          loading: () => _LoadingResult(query: submittedQuery),
          error: (message) => Text(message),
          data: (results) => _SearchResults(results: results, isStale: isStale),
        ),
      ),
    );
  }
}

class _StaleBadge extends StatelessWidget {
  const _StaleBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'STALE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
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
      child: Text('Run the race to see which response wins.'),
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
  final bool isStale;

  const _SearchResults({required this.results, required this.isStale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final result in results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isStale
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: isStale ? scheme.error : scheme.primary,
            ),
            title: Text(result.title),
            subtitle: Text(result.detail),
          ),
        if (isStale) ...[
          const SizedBox(height: 8),
          Text(
            'These answer “f” — you asked for “flutter”.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
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
                'Press play. “f” goes out slow, “flutter” goes out fast.',
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
    final scheme = Theme.of(context).colorScheme;
    final color = switch (event.kind) {
      SearchRaceEventKind.request => scheme.primary,
      SearchRaceEventKind.cancelled => Colors.amber.shade900,
      SearchRaceEventKind.success => Colors.green.shade700,
      SearchRaceEventKind.stale => scheme.error,
      SearchRaceEventKind.lateArrival => scheme.onSurfaceVariant,
      SearchRaceEventKind.lifecycle => scheme.tertiary,
    };
    final icon = switch (event.kind) {
      SearchRaceEventKind.request => Icons.play_circle_outline_rounded,
      SearchRaceEventKind.cancelled => Icons.cancel_outlined,
      SearchRaceEventKind.success => Icons.check_circle_outline_rounded,
      SearchRaceEventKind.stale => Icons.error_outline_rounded,
      SearchRaceEventKind.lateArrival => Icons.history_rounded,
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
  final bool piperEnabled;
  final int cancellations;
  final int staleOverwrites;

  const _ProofStrip({
    required this.hasRun,
    required this.piperEnabled,
    required this.cancellations,
    required this.staleOverwrites,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final String message;
    final Color background;
    final Color foreground;
    final IconData icon;

    if (staleOverwrites > 0) {
      message =
          'Without Piper: the late “f” response replaced the '
          '“flutter” results you asked for.';
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      icon = Icons.error_outline_rounded;
    } else if (piperEnabled && cancellations > 0) {
      message =
          'With Piper: the “flutter” results stayed — the slow task was '
          'cancelled before its response could land.';
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
      icon = Icons.verified_rounded;
    } else if (hasRun) {
      message = 'Race in progress…';
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
      icon = Icons.timer_outlined;
    } else {
      message = 'Run the race in both modes and compare the outcome.';
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
      icon = Icons.flag_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: foreground),
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
        Text('What this shows', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Every keystroke can start a request, and responses come back in '
          'any order. Without cancellation, whichever response lands last '
          'wins — even when it answers a query the user has moved past. '
          'Piper ties each task to its ViewModel: starting a newer search '
          'cancels the old task, so the late response has nowhere to write. '
          'Leaving the screen disposes the ViewModel and cancels everything '
          'with it.',
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _Panel({required this.title, required this.child, this.trailing});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
