package service

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/repository"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatalf("failed to open db: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.TripPost{}, &models.Media{}, &models.PointsHistory{}, &models.Reward{}, &models.Redemption{}); err != nil {
		t.Fatalf("failed to migrate: %v", err)
	}
	return db
}

func TestCreateTripAwardsPoints(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	lb := NewMemoryLeaderboard()
	service := NewTripService(tripRepo, userRepo, lb)

	user := &models.User{Username: "alice", Email: "alice@example.com", Password: "secret"}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	meta, _ := json.Marshal(map[string]interface{}{
		"captured_at": time.Now().Add(-time.Hour),
		"latitude":    10.1,
		"longitude":   20.2,
		"device":      "sony-a7",
		"signature":   "trusted-source",
	})

	trip, err := service.CreateTrip(CreateTripInput{
		UserID:      user.ID,
		Title:       "Trip",
		Description: "Beautiful place",
		Location:    "Somewhere",
		VisitedAt:   time.Now().Add(-2 * time.Hour),
		Media: []models.Media{{
			Type:        "image",
			URL:         "https://example.com/image.jpg",
			Checksum:    "58d3e5cfa20c8c2d2a5f8ff1e9fcdc84f1147aa2c3e8cb1c6888f0e9cb9e7a34",
			MetadataRaw: string(meta),
		}},
	})
	if err != nil {
		t.Fatalf("expected trip creation to succeed, got %v", err)
	}

	if !trip.Verified {
		t.Fatalf("expected trip to be verified")
	}

	if trip.Score < 90 {
		t.Fatalf("expected score to reflect high confidence, got %v", trip.Score)
	}

	updated, err := userRepo.FindByID(user.ID)
	if err != nil {
		t.Fatalf("failed to load user: %v", err)
	}

	if updated.Points < 50 {
		t.Fatalf("expected user points to increase, got %d", updated.Points)
	}

	entries, err := lb.Top(5)
	if err != nil {
		t.Fatalf("leaderboard error: %v", err)
	}
	if len(entries) == 0 || entries[0].UserID != user.ID {
		t.Fatalf("expected leaderboard to include user")
	}
}

func TestCreateTripRejectsInvalidMedia(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	service := NewTripService(tripRepo, userRepo, NewMemoryLeaderboard())

	user := &models.User{Username: "bob", Email: "bob@example.com", Password: "secret"}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	_, err := service.CreateTrip(CreateTripInput{
		UserID:      user.ID,
		Title:       "Trip",
		Description: "Nice",
		Location:    "World",
		VisitedAt:   time.Now(),
		Media: []models.Media{{
			Type:        "image",
			URL:         "https://example.com/image.jpg",
			MetadataRaw: "{}",
		}},
	})
	if err == nil {
		t.Fatalf("expected error for invalid metadata")
	}
}

func TestCreateTripRejectsInconsistentCaptureTime(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	service := NewTripService(tripRepo, userRepo, NewMemoryLeaderboard())

	user := &models.User{Username: "carol", Email: "carol@example.com", Password: "secret"}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	meta, _ := json.Marshal(map[string]interface{}{
		"captured_at": time.Now().Add(-200 * time.Hour),
		"latitude":    30.1,
		"longitude":   10.2,
	})

	_, err := service.CreateTrip(CreateTripInput{
		UserID:      user.ID,
		Title:       "Trip",
		Description: "Nice",
		Location:    "World",
		VisitedAt:   time.Now(),
		Media: []models.Media{{
			Type:        "image",
			URL:         "https://example.com/image.jpg",
			MetadataRaw: string(meta),
		}},
	})
	if err == nil {
		t.Fatalf("expected error for inconsistent capture time")
	}
}

func TestCreateTripLowConfidenceNotVerified(t *testing.T) {
	db := setupTestDB(t)
	userRepo := repository.NewUserRepository(db)
	tripRepo := repository.NewTripRepository(db)
	service := NewTripService(tripRepo, userRepo, NewMemoryLeaderboard())

	user := &models.User{Username: "dave", Email: "dave@example.com", Password: "secret"}
	if err := userRepo.Create(user); err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	meta, _ := json.Marshal(map[string]interface{}{
		"captured_at": time.Now(),
		"latitude":    11.4,
		"longitude":   23.5,
	})

	trip, err := service.CreateTrip(CreateTripInput{
		UserID:      user.ID,
		Title:       "Trip",
		Description: "Low confidence",
		Location:    "Somewhere",
		VisitedAt:   time.Now().Add(12 * time.Hour),
		Media: []models.Media{{
			Type:        "image",
			URL:         "https://example.com/photo.jpg",
			MetadataRaw: string(meta),
		}},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if trip.Verified {
		t.Fatalf("expected trip to be unverified due to low confidence")
	}

	if trip.Score >= 60 {
		t.Fatalf("expected low score, got %v", trip.Score)
	}

	updated, err := userRepo.FindByID(user.ID)
	if err != nil {
		t.Fatalf("failed to load user: %v", err)
	}
	if updated.Points != 40 {
		t.Fatalf("expected 40 points awarded, got %d", updated.Points)
	}
}
