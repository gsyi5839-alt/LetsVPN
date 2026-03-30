import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/notifier/bundled_software_notifier.dart';
import 'package:hiddify/features/bundled_software/notifier/bundled_software_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BundledSoftwarePage extends HookConsumerWidget {
  const BundledSoftwarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final state = ref.watch(bundledSoftwareNotifierProvider);
    final notifier = ref.read(bundledSoftwareNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Software'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.fetchSoftwareList(force: true),
          ),
        ],
      ),
      body: state.when(
        initial: () => const _InitialView(),
        loading: () => const _LoadingView(),
        loaded: (software, hasUpdates, pendingCount, updateAvailableCount) =>
          _LoadedView(
            software: software,
            onInstall: (s) => notifier.installSoftware(s),
            onInstallAll: pendingCount > 0 ? () => notifier.installAllPending() : null,
            onSkip: (s) => notifier.skipSoftware(s),
            onToggle: (s) => notifier.toggleEnabled(s),
          ),
        installing: (software, current) => _InstallingView(
          software: software,
          current: current,
        ),
        error: (failure) => _ErrorView(
          onRetry: () => notifier.fetchSoftwareList(force: true),
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Initializing...'),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load software list'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final List<BundledSoftwareEntity> software;
  final ValueChanged<BundledSoftwareEntity> onInstall;
  final VoidCallback? onInstallAll;
  final ValueChanged<BundledSoftwareEntity> onSkip;
  final ValueChanged<BundledSoftwareEntity> onToggle;

  const _LoadedView({
    required this.software,
    required this.onInstall,
    required this.onInstallAll,
    required this.onSkip,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (software.isEmpty) {
      return const Center(
        child: Text('No recommended software available'),
      );
    }

    return Column(
      children: [
        if (onInstallAll != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onInstallAll,
                icon: const Icon(Icons.download),
                label: const Text('Install All Pending'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: software.length,
            itemBuilder: (context, index) {
              final s = software[index];
              return _SoftwareListTile(
                software: s,
                onInstall: () => onInstall(s),
                onSkip: () => onSkip(s),
                onToggle: () => onToggle(s),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SoftwareListTile extends StatelessWidget {
  final BundledSoftwareEntity software;
  final VoidCallback onInstall;
  final VoidCallback onSkip;
  final VoidCallback onToggle;

  const _SoftwareListTile({
    required this.software,
    required this.onInstall,
    required this.onSkip,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _StatusIcon(status: software.status),
        title: Text(software.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (software.description != null)
              Text(software.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '${software.publisher ?? 'Unknown'} • ${software.packageSize ?? 'Unknown size'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (software.installedVersion != null)
              Text(
                'Installed: ${software.installedVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: software.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            if (software.status == BundledSoftwareStatus.pending ||
                software.status == BundledSoftwareStatus.updateAvailable)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: onInstall,
              )
            else if (software.status == BundledSoftwareStatus.installSuccess)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (software.status.hasError)
              IconButton(
                icon: const Icon(Icons.error, color: Colors.red),
                onPressed: onInstall,
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final BundledSoftwareStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      BundledSoftwareStatus.pending =>
        const Icon(Icons.pending, color: Colors.grey),
      BundledSoftwareStatus.downloading =>
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      BundledSoftwareStatus.downloadFailed =>
        const Icon(Icons.error_outline, color: Colors.red),
      BundledSoftwareStatus.installing =>
        const Icon(Icons.install_desktop, color: Colors.blue),
      BundledSoftwareStatus.installSuccess =>
        const Icon(Icons.check_circle, color: Colors.green),
      BundledSoftwareStatus.installFailed =>
        const Icon(Icons.error, color: Colors.red),
      BundledSoftwareStatus.updateAvailable =>
        const Icon(Icons.update, color: Colors.orange),
      BundledSoftwareStatus.skipped =>
        const Icon(Icons.skip_next, color: Colors.grey),
    };
  }
}

class _InstallingView extends StatelessWidget {
  final List<BundledSoftwareEntity> software;
  final BundledSoftwareEntity current;

  const _InstallingView({
    required this.software,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Installing ${current.title}...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _getStatusText(current.status),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          value: software.where((s) => s.status.isTerminal).length / software.length,
        ),
        const SizedBox(height: 8),
        Text(
          '${software.where((s) => s.status.isTerminal).length} of ${software.length} completed',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getStatusText(BundledSoftwareStatus status) {
    return switch (status) {
      BundledSoftwareStatus.downloading => 'Downloading...',
      BundledSoftwareStatus.installing => 'Installing...',
      _ => 'Processing...',
    };
  }
}
