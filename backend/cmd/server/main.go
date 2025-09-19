package main

import (
	"log"

	"github.com/example/solo_journey/internal/config"
	"github.com/example/solo_journey/internal/database"
	"github.com/example/solo_journey/internal/repository"
	"github.com/example/solo_journey/internal/service"
	httptransport "github.com/example/solo_journey/internal/transport/http"
)

func main() {
	cfg := config.Load()

	db := database.NewDatabase(cfg)

	userRepo := repository.NewUserRepository(db.DB)
	tripRepo := repository.NewTripRepository(db.DB)
	rewardRepo := repository.NewRewardRepository(db.DB)

	var leaderboard service.Leaderboard
	if lb := service.NewRedisLeaderboard(cfg.RedisAddr); lb != nil {
		leaderboard = lb
		log.Printf("using redis leaderboard at %s", cfg.RedisAddr)
	} else {
		leaderboard = service.NewMemoryLeaderboard()
		log.Printf("using in-memory leaderboard")
	}

	authService := service.NewAuthService(userRepo, cfg)
	tripService := service.NewTripService(tripRepo, userRepo, leaderboard)
	rewardService := service.NewRewardService(rewardRepo, userRepo)
	userService := service.NewUserService(userRepo, tripRepo, rewardRepo)

	router := httptransport.NewRouter(authService, tripService, rewardService, userService)

	log.Printf("starting server on :%s", cfg.ServerPort)
	if err := router.Engine.Run(":" + cfg.ServerPort); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
