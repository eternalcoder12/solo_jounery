package service

import (
	"errors"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/repository"
)

type RewardService struct {
	rewards *repository.RewardRepository
	users   *repository.UserRepository
}

func NewRewardService(rewards *repository.RewardRepository, users *repository.UserRepository) *RewardService {
	return &RewardService{rewards: rewards, users: users}
}

func (s *RewardService) ListRewards() ([]models.Reward, error) {
	return s.rewards.List()
}

func (s *RewardService) Redeem(userID uint, rewardID uint) (*models.Redemption, *models.User, error) {
	reward, err := s.rewards.FindByID(rewardID)
	if err != nil {
		return nil, nil, err
	}

	if reward.Inventory <= 0 {
		return nil, nil, errors.New("reward unavailable")
	}

	user, err := s.users.RedeemPoints(userID, reward.PointsCost)
	if err != nil {
		return nil, nil, err
	}

	reward.Inventory--
	if err := s.rewards.Update(reward); err != nil {
		return nil, nil, err
	}

	redemption := &models.Redemption{UserID: user.ID, RewardID: reward.ID, Status: "pending"}
	if err := s.rewards.CreateRedemption(redemption); err != nil {
		return nil, nil, err
	}
	return redemption, user, nil
}
