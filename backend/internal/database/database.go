package database

import (
	"log"

	"github.com/example/solo_journey/internal/config"
	"github.com/example/solo_journey/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type Database struct {
	DB *gorm.DB
}

func NewDatabase(cfg config.Config) *Database {
	db, err := gorm.Open(sqlite.Open(cfg.DatabasePath), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect database: %v", err)
	}

	if err := db.AutoMigrate(&models.User{}, &models.TripPost{}, &models.Media{}, &models.Reward{}, &models.Redemption{}, &models.PointsHistory{}); err != nil {
		log.Fatalf("failed to migrate database: %v", err)
	}

	return &Database{DB: db}
}
