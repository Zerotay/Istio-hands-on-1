package entity

type Header struct {
	Key     string   `json:"key" validate:"required"`
	Values  []string `json:"values" `
	Weights []int    `json:"weights"`
}
