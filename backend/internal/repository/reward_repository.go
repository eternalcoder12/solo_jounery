package repository

import (
	"github.com/example/solo_journey/internal/models"
	"gorm.io/gorm"
)

type RewardRepository struct {
	db *gorm.DB
}

func NewRewardRepository(db *gorm.DB) *RewardRepository {
	return &RewardRepository{db: db}
}

func (r *RewardRepository) List() ([]models.Reward, error) {
	var rewards []models.Reward
	if err := r.db.Find(&rewards).Error; err != nil {
		return nil, err
	}
	return rewards, nil
}

func (r *RewardRepository) Create(reward *models.Reward) error {
	return r.db.Create(reward).Error
}

func (r *RewardRepository) FindByID(id uint) (*models.Reward, error) {
	var reward models.Reward
	if err := r.db.First(&reward, id).Error; err != nil {
		return nil, err
	}
	return &reward, nil
}

func (r *RewardRepository) Update(reward *models.Reward) error {
	return r.db.Save(reward).Error
}

func (r *RewardRepository) CreateRedemption(redemption *models.Redemption) error {
	return r.db.Create(redemption).Error
}

func (r *RewardRepository) ListRedemptionsByUser(userID uint, limit int) ([]models.Redemption, error) {
	var redemptions []models.Redemption
	query := r.db.Preload("Reward").Where("user_id = ?", userID).Order("created_at desc")
	if limit > 0 {
		query = query.Limit(limit)
	}
	if err := query.Find(&redemptions).Error; err != nil {
		return nil, err
	}
	return redemptions, nil
}

func (r *RewardRepository) CountRedemptionsByUser(userID uint) (int64, error) {
	var count int64
	if err := r.db.Model(&models.Redemption{}).Where("user_id = ?", userID).Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}
