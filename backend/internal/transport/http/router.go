package http

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/example/solo_journey/internal/models"
	"github.com/example/solo_journey/internal/service"
)

type Router struct {
	Engine        *gin.Engine
	authService   *service.AuthService
	tripService   *service.TripService
	rewardService *service.RewardService
	userService   *service.UserService
}

func NewRouter(auth *service.AuthService, trip *service.TripService, reward *service.RewardService, user *service.UserService) *Router {
	r := &Router{
		authService:   auth,
		tripService:   trip,
		rewardService: reward,
		userService:   user,
		Engine:        gin.Default(),
	}

	r.registerRoutes()
	return r
}

func (r *Router) registerRoutes() {
	api := r.Engine.Group("/api/v1")

	auth := api.Group("/auth")
	auth.POST("/register", r.handleRegister)
	auth.POST("/login", r.handleLogin)

	trips := api.Group("/trips")
	trips.GET("", r.handleListTrips)
	trips.GET("/:id", r.handleGetTrip)
	trips.POST("", r.requireAuth(), r.handleCreateTrip)

	leaderboard := api.Group("/leaderboard")
	leaderboard.GET("", r.handleLeaderboard)

	rewards := api.Group("/rewards")
	rewards.GET("", r.handleListRewards)
	rewards.POST("/redeem", r.requireAuth(), r.handleRedeemReward)

	me := api.Group("/me")
	me.Use(r.requireAuth())
	me.GET("", r.handleGetProfile)
	me.GET("/history", r.handleGetHistory)
	me.GET("/redemptions", r.handleGetRedemptions)
}

func (r *Router) handleRegister(c *gin.Context) {
	var input struct {
		Username string `json:"username" binding:"required,min=3"`
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=8"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := r.authService.Register(input.Username, input.Email, input.Password)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, user)
}

func (r *Router) handleLogin(c *gin.Context) {
	var input struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, user, err := r.authService.Login(input.Email, input.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": token, "user": user})
}

func (r *Router) handleCreateTrip(c *gin.Context) {
	claims := c.MustGet("claims").(*service.Claims)
	var input struct {
		Title       string `json:"title" binding:"required"`
		Description string `json:"description" binding:"required"`
		Location    string `json:"location" binding:"required"`
		VisitedAt   string `json:"visited_at" binding:"required"`
		Media       []struct {
			Type        string `json:"type" binding:"required"`
			URL         string `json:"url" binding:"required"`
			Checksum    string `json:"checksum"`
			MetadataRaw string `json:"metadata_raw" binding:"required"`
		} `json:"media" binding:"required,dive"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	visitedAt, err := time.Parse(time.RFC3339, input.VisitedAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "visited_at must be RFC3339 timestamp"})
		return
	}

	media := make([]models.Media, len(input.Media))
	for i, m := range input.Media {
		media[i] = models.Media{
			Type:        m.Type,
			URL:         m.URL,
			Checksum:    m.Checksum,
			MetadataRaw: m.MetadataRaw,
		}
	}

	trip, err := r.tripService.CreateTrip(service.CreateTripInput{
		UserID:      claims.UserID,
		Title:       input.Title,
		Description: input.Description,
		Location:    input.Location,
		VisitedAt:   visitedAt,
		Media:       media,
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, trip)
}

func (r *Router) handleListTrips(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	trips, err := r.tripService.ListTrips(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, trips)
}

func (r *Router) handleGetTrip(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid trip id"})
		return
	}
	trip, err := r.tripService.GetTrip(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, trip)
}

func (r *Router) handleLeaderboard(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	entries, err := r.tripService.Leaderboard(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, entries)
}

func (r *Router) handleListRewards(c *gin.Context) {
	rewards, err := r.rewardService.ListRewards()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rewards)
}

func (r *Router) handleRedeemReward(c *gin.Context) {
	claims := c.MustGet("claims").(*service.Claims)
	var input struct {
		RewardID uint `json:"reward_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	redemption, user, err := r.rewardService.Redeem(claims.UserID, input.RewardID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"redemption": redemption, "user": user})
}

func (r *Router) handleGetProfile(c *gin.Context) {
	claims := c.MustGet("claims").(*service.Claims)
	profile, err := r.userService.Profile(claims.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, profile)
}

func (r *Router) handleGetHistory(c *gin.Context) {
	claims := c.MustGet("claims").(*service.Claims)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	history, err := r.userService.PointsHistory(claims.UserID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

func (r *Router) handleGetRedemptions(c *gin.Context) {
	claims := c.MustGet("claims").(*service.Claims)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	redemptions, err := r.userService.Redemptions(claims.UserID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, redemptions)
}

func (r *Router) requireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			return
		}

		claims, err := r.authService.ParseToken(parts[1])
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		c.Set("claims", claims)
		c.Next()
	}
}
