package repository

import (
	"errors"

	"github.com/example/solo_journey/internal/models"
	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) FindByID(id uint) (*models.User, error) {
	var user models.User
	if err := r.db.First(&user, id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}

func (r *UserRepository) IncrementPoints(userID uint, delta int64) (*models.User, error) {
	var user models.User
	if err := r.db.First(&user, userID).Error; err != nil {
		return nil, err
	}

	user.Points += delta
	user.Level = calculateLevel(user.Points)

	if err := r.db.Save(&user).Error; err != nil {
		return nil, err
	}

	history := models.PointsHistory{UserID: user.ID, Delta: delta, Reason: "activity"}
	if err := r.db.Create(&history).Error; err != nil {
		return nil, err
	}

	return &user, nil
}

var levelThresholds = []int64{0, 100, 500, 1000, 2000, 5000}

func calculateLevel(points int64) int {
	level := 0
	for i := len(levelThresholds) - 1; i >= 0; i-- {
		if points >= levelThresholds[i] {
			level = i
			break
		}
	}
	return level
}

// LevelProgress returns the current level, the next achievable level and
// how many more points are required to reach it. When the user is already at
// the highest level the returned next level equals the current level and the
// remaining points are zero.
func LevelProgress(points int64) (current int, next int, remaining int64) {
	current = calculateLevel(points)
	if current >= len(levelThresholds)-1 {
		return current, current, 0
	}
	next = current + 1
	remaining = levelThresholds[next] - points
	if remaining < 0 {
		remaining = 0
	}
	return current, next, remaining
}

func LevelThreshold(level int) int64 {
	if level < 0 {
		return levelThresholds[0]
	}
	if level >= len(levelThresholds) {
		return levelThresholds[len(levelThresholds)-1]
	}
	return levelThresholds[level]
}

var ErrInsufficientPoints = errors.New("insufficient points")

func (r *UserRepository) RedeemPoints(userID uint, cost int64) (*models.User, error) {
	var user models.User
	if err := r.db.First(&user, userID).Error; err != nil {
		return nil, err
	}

	if user.Points < cost {
		return nil, ErrInsufficientPoints
	}

	user.Points -= cost
	user.Level = calculateLevel(user.Points)

	if err := r.db.Save(&user).Error; err != nil {
		return nil, err
	}

	history := models.PointsHistory{UserID: user.ID, Delta: -cost, Reason: "redeem"}
	return &user, r.db.Create(&history).Error
}

func (r *UserRepository) PointsHistory(userID uint, limit int) ([]models.PointsHistory, error) {
	var history []models.PointsHistory
	query := r.db.Where("user_id = ?", userID).Order("created_at desc")
	if limit > 0 {
		query = query.Limit(limit)
	}
	if err := query.Find(&history).Error; err != nil {
		return nil, err
	}
	return history, nil
}
