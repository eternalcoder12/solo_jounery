import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.leaderboard;
    final currentUserId = state.profile?.user.id;
    final currentPoints = state.profile?.user.points ?? state.currentUser?.points ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<AppState>().loadLeaderboard(),
          context.read<AppState>().loadProfile(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${state.profile?.user.level ?? state.currentUser?.level ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.profile?.user.username ?? state.currentUser?.username ?? '旅行者',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('当前积分 $currentPoints', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<AppState>().refreshAll(),
                    icon: state.syncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('排行榜暂时为空，快去发布旅程获取积分吧！',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final isCurrent = entry.userId == currentUserId;
              return Card(
                elevation: isCurrent ? 4 : 0,
                color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text('#${index + 1}'),
                  ),
                  title: Text(isCurrent ? '你' : '用户 ${entry.userId}'),
                  subtitle: isCurrent ? const Text('继续努力，冲击更高段位！') : null,
                  trailing: Text('${entry.points} 积分'),
                ),
              );
            }),
        ],
      ),
    );
  }
}
