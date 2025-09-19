package models

import "time"

type TripPost struct {
        ID          uint      `gorm:"primaryKey" json:"id"`
        CreatedAt   time.Time `json:"created_at"`
        UpdatedAt   time.Time `json:"updated_at"`
        UserID      uint      `json:"user_id"`
        Title       string    `json:"title"`
        Description string    `json:"description"`
        Location    string    `json:"location"`
        VisitedAt   time.Time `json:"visited_at"`
        User        User      `json:"user"`
        Media       []Media   `gorm:"constraint:OnDelete:CASCADE;" json:"media"`
        Score       float64   `json:"score"`
        Verified    bool      `json:"verified"`
}

type Media struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	TripPostID  uint      `json:"trip_post_id"`
	Type        string    `json:"type"`
	URL         string    `json:"url"`
	Checksum    string    `json:"checksum"`
        MetadataRaw string    `json:"metadata_raw,omitempty"`
}
