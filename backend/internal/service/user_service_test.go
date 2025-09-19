package service

import (
	"testing"
	"time"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/repository"
)

func TestUserProfileAggregatesStats(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	rewardRepo := repository.NewRewardRepository(db)
	service := NewUserService(userRepo, tripRepo, rewardRepo)

	user := &models.User{Username: "eva", Email: "eva@example.com", Password: "secret", Points: 550, Level: 2}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	if err := db.Create(&models.PointsHistory{UserID: user.ID, Delta: 50, Reason: "activity"}).Error; err != nil {
		t.Fatalf("failed to create history: %v", err)
	}
	if err := db.Create(&models.PointsHistory{UserID: user.ID, Delta: -20, Reason: "redeem"}).Error; err != nil {
		t.Fatalf("failed to create history: %v", err)
	}

	trip := models.TripPost{UserID: user.ID, Title: "Mountain", Score: 75, VisitedAt: time.Now(), Media: []models.Media{{Type: "image", URL: "https://example.com"}}}
	if err := db.Create(&trip).Error; err != nil {
		t.Fatalf("failed to create trip: %v", err)
	}

	reward := &models.Reward{Name: "Coffee", PointsCost: 100, Inventory: 5}
	if err := rewardRepo.Create(reward); err != nil {
		t.Fatalf("failed to create reward: %v", err)
	}
	redemption := models.Redemption{UserID: user.ID, RewardID: reward.ID, Status: "completed"}
	if err := db.Create(&redemption).Error; err != nil {
		t.Fatalf("failed to create redemption: %v", err)
	}

	profile, err := service.Profile(user.ID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.User.ID != user.ID {
		t.Fatalf("expected user ID %d, got %d", user.ID, profile.User.ID)
	}
	if profile.TotalTrips != 1 {
		t.Fatalf("expected total trips to be 1, got %d", profile.TotalTrips)
	}
	if profile.TotalRedemptions != 1 {
		t.Fatalf("expected total redemptions to be 1, got %d", profile.TotalRedemptions)
	}
	if len(profile.RecentHistory) != 2 {
		t.Fatalf("expected 2 history entries, got %d", len(profile.RecentHistory))
	}
	if len(profile.RecentRedemptions) != 1 {
		t.Fatalf("expected 1 redemption entry, got %d", len(profile.RecentRedemptions))
	}
	if len(profile.RecentTrips) != 1 {
		t.Fatalf("expected 1 recent trip, got %d", len(profile.RecentTrips))
	}
	if profile.NextLevel != 3 {
		t.Fatalf("expected next level 3, got %d", profile.NextLevel)
	}
	if profile.PointsToNext != 450 {
		t.Fatalf("expected 450 points to next level, got %d", profile.PointsToNext)
	}
	if profile.CurrentLevelFloor != 500 {
		t.Fatalf("expected current level floor 500, got %d", profile.CurrentLevelFloor)
	}
	if profile.NextLevelThreshold != 1000 {
		t.Fatalf("expected next level threshold 1000, got %d", profile.NextLevelThreshold)
	}
	if profile.AverageScore < 70 || profile.AverageScore > 80 {
		t.Fatalf("expected average score around 75, got %v", profile.AverageScore)
	}
}

func TestUserServiceHistoryLimit(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	rewardRepo := repository.NewRewardRepository(db)
	service := NewUserService(userRepo, tripRepo, rewardRepo)

	user := &models.User{Username: "li", Email: "li@example.com", Password: "secret"}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	for i := 0; i < 5; i++ {
		if err := db.Create(&models.PointsHistory{UserID: user.ID, Delta: int64(i + 1), Reason: "activity"}).Error; err != nil {
			t.Fatalf("failed to seed history: %v", err)
		}
	}

	history, err := service.PointsHistory(user.ID, 3)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(history) != 3 {
		t.Fatalf("expected 3 history items, got %d", len(history))
	}
}
