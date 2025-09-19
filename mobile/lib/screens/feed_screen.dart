import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/media.dart';
import '../models/trip.dart';
import '../services/app_state.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final trips = state.trips;

    if (trips.isEmpty) {
      return Center(
        child: state.loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无旅程，快去分享你的故事吧！'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<AppState>().loadTrips(),
                    child: const Text('刷新'),
                  ),
                ],
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadTrips(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) => TripCard(trip: trips[index]),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy年MM月dd日');
    final image = _coverMedia(trip.media);
    final theme = Theme.of(context);
    final confidence = (trip.score.clamp(0, 100)) / 100;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(trip.author.characters.first.toUpperCase())),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.author, style: theme.textTheme.titleMedium),
                    Text(formatter.format(trip.visitedAt), style: theme.textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                if (trip.verified)
                  const Chip(
                    label: Text('已验证'),
                    avatar: Icon(Icons.verified, color: Colors.blue, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(trip.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(trip.description),
            const SizedBox(height: 8),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            if (image != null) const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: trip.media
                  .map((media) => Chip(
                        avatar: Icon(
                          media.type == 'video' ? Icons.videocam : Icons.photo,
                          size: 16,
                        ),
                        label: Text(media.type),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(trip.location),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('可信度 ${(trip.score).toStringAsFixed(1)}%', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Icon(confidence > 0.75 ? Icons.brightness_high : Icons.brightness_medium,
                        color: theme.colorScheme.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: confidence.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MediaItem? _coverMedia(List<MediaItem> media) {
    if (media.isEmpty) return null;
    return media.firstWhere(
      (item) => item.type == 'image',
      orElse: () => media.first,
    );
  }
}
