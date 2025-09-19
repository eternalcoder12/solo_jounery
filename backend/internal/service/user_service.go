package service

import (
	"math"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/repository"
)

type UserService struct {
	users   *repository.UserRepository
	trips   *repository.TripRepository
	rewards *repository.RewardRepository
}

type Profile struct {
	User               *models.User           `json:"user"`
	NextLevel          int                    `json:"next_level"`
	PointsToNext       int64                  `json:"points_to_next"`
	CurrentLevelFloor  int64                  `json:"current_level_floor"`
	NextLevelThreshold int64                  `json:"next_level_threshold"`
	TotalTrips         int64                  `json:"total_trips"`
	TotalRedemptions   int64                  `json:"total_redemptions"`
	AverageScore       float64                `json:"average_score"`
	RecentHistory      []models.PointsHistory `json:"recent_history"`
	RecentRedemptions  []models.Redemption    `json:"recent_redemptions"`
	RecentTrips        []models.TripPost      `json:"recent_trips"`
}

func NewUserService(users *repository.UserRepository, trips *repository.TripRepository, rewards *repository.RewardRepository) *UserService {
	return &UserService{users: users, trips: trips, rewards: rewards}
}

func (s *UserService) Profile(userID uint) (*Profile, error) {
	user, err := s.users.FindByID(userID)
	if err != nil {
		return nil, err
	}

	totalTrips, err := s.trips.CountByUser(userID)
	if err != nil {
		return nil, err
	}

	avgScore, err := s.trips.AverageScoreByUser(userID)
	if err != nil {
		return nil, err
	}

	totalRedemptions, err := s.rewards.CountRedemptionsByUser(userID)
	if err != nil {
		return nil, err
	}

	history, err := s.users.PointsHistory(userID, 10)
	if err != nil {
		return nil, err
	}

	redemptions, err := s.rewards.ListRedemptionsByUser(userID, 10)
	if err != nil {
		return nil, err
	}

	recentTrips, err := s.trips.ListByUser(userID, 3)
	if err != nil {
		return nil, err
	}

	current, next, remaining := repository.LevelProgress(user.Points)
	currentFloor := repository.LevelThreshold(current)
	nextThreshold := repository.LevelThreshold(next)

	return &Profile{
		User:               user,
		NextLevel:          next,
		PointsToNext:       remaining,
		CurrentLevelFloor:  currentFloor,
		NextLevelThreshold: nextThreshold,
		TotalTrips:         totalTrips,
		TotalRedemptions:   totalRedemptions,
		AverageScore:       math.Round(avgScore*100) / 100,
		RecentHistory:      history,
		RecentRedemptions:  redemptions,
		RecentTrips:        recentTrips,
	}, nil
}

func (s *UserService) PointsHistory(userID uint, limit int) ([]models.PointsHistory, error) {
	return s.users.PointsHistory(userID, limit)
}

func (s *UserService) Redemptions(userID uint, limit int) ([]models.Redemption, error) {
	return s.rewards.ListRedemptionsByUser(userID, limit)
}
