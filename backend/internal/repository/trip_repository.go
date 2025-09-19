package repository

import (
	"database/sql"

	"github.com/example/solo_journey/internal/models"
	"gorm.io/gorm"
)

type TripRepository struct {
	db *gorm.DB
}

func NewTripRepository(db *gorm.DB) *TripRepository {
	return &TripRepository{db: db}
}

func (r *TripRepository) Create(trip *models.TripPost) error {
	return r.db.Create(trip).Error
}

func (r *TripRepository) List(limit int) ([]models.TripPost, error) {
	var trips []models.TripPost
	if err := r.db.Preload("Media").Preload("User").Order("created_at desc").Limit(limit).Find(&trips).Error; err != nil {
		return nil, err
	}
	return trips, nil
}

func (r *TripRepository) GetByID(id uint) (*models.TripPost, error) {
	var trip models.TripPost
	if err := r.db.Preload("Media").Preload("User").First(&trip, id).Error; err != nil {
		return nil, err
	}
	return &trip, nil
}

func (r *TripRepository) ListByUser(userID uint, limit int) ([]models.TripPost, error) {
	var trips []models.TripPost
	query := r.db.Preload("Media").Preload("User").Where("user_id = ?", userID).Order("visited_at desc")
	if limit > 0 {
		query = query.Limit(limit)
	}
	if err := query.Find(&trips).Error; err != nil {
		return nil, err
	}
	return trips, nil
}

func (r *TripRepository) CountByUser(userID uint) (int64, error) {
	var count int64
	if err := r.db.Model(&models.TripPost{}).Where("user_id = ?", userID).Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

func (r *TripRepository) AverageScoreByUser(userID uint) (float64, error) {
	var avg sql.NullFloat64
	if err := r.db.Model(&models.TripPost{}).Where("user_id = ?", userID).Select("avg(score)").Scan(&avg).Error; err != nil {
		return 0, err
	}
	if avg.Valid {
		return avg.Float64, nil
	}
	return 0, nil
}
