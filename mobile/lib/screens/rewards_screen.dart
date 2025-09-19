import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reward.dart';
import '../services/app_state.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rewards = state.rewards;
    final profile = state.profile;

    if (rewards.isEmpty) {
      return Center(
        child: state.loading
            ? const CircularProgressIndicator()
            : const Text('暂时没有可兑换的奖励'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadRewards(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前可用积分', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text('${profile?.user.points ?? state.currentUser?.points ?? 0}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('等级 ${profile?.user.level ?? state.currentUser?.level ?? 0}'),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        final appState = context.read<AppState>();
                        await appState.loadRedemptions(limit: 20);
                        if (!context.mounted) return;
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: appState,
                            child: const RedemptionHistorySheet(),
                          ),
                        );
                      },
                      child: const Text('查看兑换记录'),
                    ),
                  ],
                ),
              ),
            );
          }
          final reward = rewards[index - 1];
          return RewardTile(reward: reward);
        },
      ),
    );
  }
}

class RedemptionHistorySheet extends StatelessWidget {
  const RedemptionHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final redemptions = state.redemptions;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.redemptionsLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('兑换记录', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (redemptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('暂无兑换记录'),
                    )
                  else
                    ...redemptions.map(
                      (entry) => ListTile(
                        leading: const Icon(Icons.card_giftcard),
                        title: Text(entry.reward?.name ?? '奖励 ${entry.id}'),
                        subtitle: Text('状态：${entry.status}'),
                        trailing: Text(entry.createdAt.toLocal().toString().substring(0, 16)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class RewardTile extends StatelessWidget {
  const RewardTile({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(reward.name),
        subtitle: Text(reward.description),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${reward.pointsCost} 积分'),
            const SizedBox(height: 4),
            Text('库存 ${reward.inventory}'),
          ],
        ),
        onTap: reward.inventory > 0
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('兑换奖励'),
                    content: Text('确定使用 ${reward.pointsCost} 积分兑换 ${reward.name} 吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AppState>().redeem(reward.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已兑换 ${reward.name}')),
                  );
                }
              }
            : null,
      ),
    );
  }
}
