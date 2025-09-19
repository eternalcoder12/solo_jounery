package models

import "time"

type Reward struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	PointsCost  int64     `json:"points_cost"`
	Inventory   int       `json:"inventory"`
}

type Redemption struct {
        ID        uint      `gorm:"primaryKey" json:"id"`
        CreatedAt time.Time `json:"created_at"`
        UserID    uint      `json:"user_id"`
        RewardID  uint      `json:"reward_id"`
        Status    string    `json:"status"`
        Reward    Reward    `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"reward"`
}
