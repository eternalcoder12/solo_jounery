package service

import (
	"context"
	"fmt"
	"sort"
	"strconv"
	"sync"

	"github.com/redis/go-redis/v9"
)

type RedisLeaderboard struct {
	client *redis.Client
	key    string
}

func NewRedisLeaderboard(addr string) *RedisLeaderboard {
	if addr == "" {
		return nil
	}
	client := redis.NewClient(&redis.Options{Addr: addr})
	return &RedisLeaderboard{client: client, key: "leaderboard:points"}
}

func (r *RedisLeaderboard) AddScore(userID uint, score int64) error {
	if r == nil || r.client == nil {
		return nil
	}
	ctx := context.Background()
	return r.client.ZAdd(ctx, r.key, redis.Z{Score: float64(score), Member: fmt.Sprint(userID)}).Err()
}

func (r *RedisLeaderboard) Top(limit int) ([]LeaderboardEntry, error) {
	if r == nil || r.client == nil {
		return nil, nil
	}
	ctx := context.Background()
	values, err := r.client.ZRevRangeWithScores(ctx, r.key, 0, int64(limit-1)).Result()
	if err != nil {
		return nil, err
	}
	entries := make([]LeaderboardEntry, 0, len(values))
	for _, v := range values {
		member := fmt.Sprint(v.Member)
		if id, err := strconv.ParseUint(member, 10, 64); err == nil {
			entries = append(entries, LeaderboardEntry{UserID: uint(id), Points: int64(v.Score)})
		}
	}
	return entries, nil
}

type MemoryLeaderboard struct {
	mu     sync.RWMutex
	scores map[uint]int64
}

func NewMemoryLeaderboard() *MemoryLeaderboard {
	return &MemoryLeaderboard{scores: make(map[uint]int64)}
}

func (m *MemoryLeaderboard) AddScore(userID uint, score int64) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.scores[userID] = score
	return nil
}

func (m *MemoryLeaderboard) Top(limit int) ([]LeaderboardEntry, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	entries := make([]LeaderboardEntry, 0, len(m.scores))
	for id, score := range m.scores {
		entries = append(entries, LeaderboardEntry{UserID: id, Points: score})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Points > entries[j].Points
	})
	if limit > 0 && len(entries) > limit {
		entries = entries[:limit]
	}
	return entries, nil
}
