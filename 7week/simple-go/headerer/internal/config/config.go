package config

import (
	"github.com/caarlos0/env/v11"
)

type Config struct {
	Port     int    `env:"PORT" envDefault:"8080"`
	Debug    bool   `env:"DEBUG" envDefault:"false"`
	Database string `env:"DATABASE" envDefault:"memory"`
}

func Load() Config {
	cfg := Config{}
	if err := env.Parse(&cfg); err != nil {
		panic("failed to parse config: " + err.Error())
	}
	return cfg
}
