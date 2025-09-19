package config

import (
	"log"
	"os"
	"time"
)

type Config struct {
	DatabasePath string
	RedisAddr    string
	JWTSecret    string
	ServerPort   string
	TokenExpiry  time.Duration
}

func Load() Config {
	cfg := Config{
		DatabasePath: getEnv("DATABASE_PATH", "solo_journey.db"),
		RedisAddr:    os.Getenv("REDIS_ADDR"),
		JWTSecret:    getEnv("JWT_SECRET", "super-secret-key"),
		ServerPort:   getEnv("SERVER_PORT", "8080"),
		TokenExpiry:  time.Hour * 24 * 7,
	}

	if v := os.Getenv("TOKEN_EXPIRY_HOURS"); v != "" {
		if d, err := time.ParseDuration(v + "h"); err == nil {
			cfg.TokenExpiry = d
		} else {
			log.Printf("invalid TOKEN_EXPIRY_HOURS value: %v", err)
		}
	}

	return cfg
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
