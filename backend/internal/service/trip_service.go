package service

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"strings"
	"time"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/repository"
)

type TripService struct {
	trips       *repository.TripRepository
	users       *repository.UserRepository
	leaderboard Leaderboard
}

type Leaderboard interface {
	AddScore(userID uint, score int64) error
	Top(limit int) ([]LeaderboardEntry, error)
}

type LeaderboardEntry struct {
	UserID uint  `json:"user_id"`
	Points int64 `json:"points"`
}

type mediaMetadata struct {
	CapturedAt time.Time `json:"captured_at"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Device     string    `json:"device"`
	Signature  string    `json:"signature"`
}

func NewTripService(trips *repository.TripRepository, users *repository.UserRepository, lb Leaderboard) *TripService {
	return &TripService{trips: trips, users: users, leaderboard: lb}
}

type CreateTripInput struct {
	UserID      uint           `json:"user_id"`
	Title       string         `json:"title"`
	Description string         `json:"description"`
	Location    string         `json:"location"`
	VisitedAt   time.Time      `json:"visited_at"`
	Media       []models.Media `json:"media"`
}

func (s *TripService) CreateTrip(input CreateTripInput) (*models.TripPost, error) {
	if len(input.Media) == 0 {
		return nil, errors.New("at least one media item is required")
	}

	verified := true
	confidenceSum := 0.0
	for i := range input.Media {
		media := &input.Media[i]
		if media.Checksum == "" {
			hash := sha256.Sum256([]byte(media.URL))
			media.Checksum = hex.EncodeToString(hash[:])
		}

		if !isValidChecksum(media.Checksum) {
			return nil, errors.New("media checksum must be a valid sha256 hex string")
		}

		meta, err := parseMediaMetadata(media.MetadataRaw)
		if err != nil {
			return nil, err
		}

		confidence, err := evaluateMetadata(meta, input.VisitedAt)
		if err != nil {
			return nil, err
		}
		confidenceSum += confidence
	}

	trip := &models.TripPost{
		UserID:      input.UserID,
		Title:       strings.TrimSpace(input.Title),
		Description: strings.TrimSpace(input.Description),
		Location:    strings.TrimSpace(input.Location),
		VisitedAt:   input.VisitedAt,
		Media:       input.Media,
		Verified:    verified,
	}

	confidence := confidenceSum / float64(len(input.Media))
	if confidence < 0.6 {
		verified = false
	}

	trip.Verified = verified
	trip.Score = math.Round(confidence*1000) / 10
	if err := s.trips.Create(trip); err != nil {
		return nil, err
	}

	bonus := int64(math.Round(confidence * 50))
	points := int64(20) + bonus
	if verified {
		points += 20
	}

	user, err := s.users.IncrementPoints(trip.UserID, points)
	if err != nil {
		return nil, err
	}

	if s.leaderboard != nil {
		_ = s.leaderboard.AddScore(user.ID, user.Points)
	}

	trip.Media = input.Media
	return trip, nil
}

func (s *TripService) ListTrips(limit int) ([]models.TripPost, error) {
	if limit <= 0 {
		limit = 20
	}
	return s.trips.List(limit)
}

func (s *TripService) GetTrip(id uint) (*models.TripPost, error) {
	return s.trips.GetByID(id)
}

func (s *TripService) Leaderboard(limit int) ([]LeaderboardEntry, error) {
	if s.leaderboard == nil {
		return nil, errors.New("leaderboard not configured")
	}
	if limit <= 0 {
		limit = 10
	}
	return s.leaderboard.Top(limit)
}

func isValidChecksum(value string) bool {
	if len(value) != 64 {
		return false
	}
	_, err := hex.DecodeString(value)
	return err == nil
}

func parseMediaMetadata(raw string) (mediaMetadata, error) {
	if raw == "" {
		return mediaMetadata{}, errors.New("media metadata is required")
	}
	var meta mediaMetadata
	if err := json.Unmarshal([]byte(raw), &meta); err != nil {
		return mediaMetadata{}, errors.New("media metadata is not valid JSON")
	}
	if meta.CapturedAt.IsZero() {
		return mediaMetadata{}, errors.New("media metadata is missing captured_at field")
	}
	if meta.Latitude < -90 || meta.Latitude > 90 || meta.Longitude < -180 || meta.Longitude > 180 {
		return mediaMetadata{}, errors.New("media metadata has invalid coordinates")
	}
	if meta.Latitude == 0 && meta.Longitude == 0 {
		return mediaMetadata{}, errors.New("media metadata is missing GPS coordinates")
	}
	return meta, nil
}

func evaluateMetadata(meta mediaMetadata, visitedAt time.Time) (float64, error) {
	diff := visitedAt.Sub(meta.CapturedAt)
	if math.Abs(diff.Hours()) > 72 {
		return 0, errors.New("media metadata capture time is inconsistent with trip date")
	}

	confidence := 0.4
	if math.Abs(diff.Hours()) <= 6 {
		confidence += 0.2
	}
	if meta.Device != "" {
		confidence += 0.2
	}
	if meta.Signature != "" {
		confidence += 0.2
	}
	if confidence > 1 {
		confidence = 1
	}
	return confidence, nil
}
