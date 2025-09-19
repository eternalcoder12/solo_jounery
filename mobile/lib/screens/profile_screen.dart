import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/points_history.dart';
import '../models/redemption.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showFullHistory = false;
  bool _showFullRedemptions = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = context.read<AppState>();
      if (state.currentUser != null && state.profile == null) {
        state.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    if (profile == null) {
      if (state.profileLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Text('暂未获取到用户信息', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final historyEntries = _showFullHistory ? state.history : profile.recentHistory;
    final redemptionEntries = _showFullRedemptions ? state.redemptions : profile.recentRedemptions;

    return RefreshIndicator(
      onRefresh: () async {
        await state.loadProfile();
        if (_showFullHistory) {
          await state.loadPointsHistory(limit: 50);
        }
        if (_showFullRedemptions) {
          await state.loadRedemptions(limit: 50);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(profile: profile),
          const SizedBox(height: 16),
          _StatsGrid(profile: profile),
          if (profile.recentTrips.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('最近旅程', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => _TripPreview(trip: profile.recentTrips[index]),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: profile.recentTrips.length,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionHeader(
            title: '积分动态',
            expanded: _showFullHistory,
            onToggle: () async {
              if (!_showFullHistory) {
                await context.read<AppState>().loadPointsHistory(limit: 50);
              }
              setState(() => _showFullHistory = !_showFullHistory);
            },
          ),
          const SizedBox(height: 8),
          _HistoryList(entries: historyEntries, isLoading: state.historyLoading && _showFullHistory),
          const SizedBox(height: 24),
          _SectionHeader(
            title: '兑换记录',
            expanded: _showFullRedemptions,
            onToggle: () async {
              if (!_showFullRedemptions) {
                await context.read<AppState>().loadRedemptions(limit: 50);
              }
              setState(() => _showFullRedemptions = !_showFullRedemptions);
            },
          ),
          const SizedBox(height: 8),
          _RedemptionList(entries: redemptionEntries, isLoading: state.redemptionsLoading && _showFullRedemptions),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextThreshold = profile.nextLevelThreshold;
    final floor = profile.currentLevelFloor;
    final span = (nextThreshold - floor).clamp(1, double.maxFinite).toDouble();
    final progress = nextThreshold == floor
        ? 1.0
        : ((profile.user.points - floor) / span).clamp(0, 1).toDouble();
    final message = profile.pointsToNext == 0
        ? '已达到最高等级'
        : '距离下一等级还需 ${profile.pointsToNext} 积分';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(profile.user.username.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.user.username, style: theme.textTheme.titleMedium),
                      Text('等级 ${profile.user.level} · 累计积分 ${profile.user.points}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.isNaN ? 0 : progress,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(label: '总旅程', value: profile.totalTrips.toString(), icon: Icons.map),
      _StatTile(label: '奖励兑换', value: profile.totalRedemptions.toString(), icon: Icons.card_giftcard),
      _StatTile(label: '平均可信度', value: '${profile.averageScore.toStringAsFixed(1)}%', icon: Icons.shield_moon),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles
          .map((tile) => SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: tile,
              ))
          .toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TripPreview extends StatelessWidget {
  const _TripPreview({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final media = trip.media.isNotEmpty ? trip.media.first : null;
    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media != null)
              Expanded(
                child: Image.network(
                  media.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.photo, size: 42, color: Colors.grey),
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(child: Icon(Icons.photo_camera_back, size: 42)),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${trip.score.toStringAsFixed(1)}% 可信度',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.expanded, required this.onToggle});

  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(expanded ? '收起' : '展开全部'),
        ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries, required this.isLoading});

  final List<PointsHistory> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MM月dd日 HH:mm');
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('暂无积分变动'),
        ),
      );
    }
    return Column(
      children: entries
          .map(
            (entry) => Card(
              child: ListTile(
                leading: Icon(
                  entry.delta >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: entry.delta >= 0 ? Colors.green : Colors.red,
                ),
                title: Text('${entry.delta >= 0 ? '+' : ''}${entry.delta} 积分'),
                subtitle: Text('${entry.reason} · ${formatter.format(entry.createdAt.toLocal())}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RedemptionList extends StatelessWidget {
  const _RedemptionList({required this.entries, required this.isLoading});

  final List<Redemption> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MM月dd日 HH:mm');
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('暂无兑换记录'),
        ),
      );
    }
    return Column(
      children: entries
          .map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(entry.reward?.name ?? '奖励 ${entry.id}'),
                subtitle: Text('状态：${entry.status} · ${formatter.format(entry.createdAt.toLocal())}'),
              ),
            ),
          )
          .toList(),
    );
  }
}
