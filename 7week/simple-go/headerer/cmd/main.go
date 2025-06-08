package main

import (
	"headerer/internal/config"
	"headerer/internal/server"
	"headerer/internal/v1/header"
	"headerer/internal/v1/storage/memory"
	"log/slog"
	"os"
)

// pick from data

func main() {
	cfg := config.Load()
	slog.SetDefault(newLogger(cfg.Debug))
	slog.Info("Starting server..")
	repo := memory.NewRepository()
	svc := header.NewService(repo)

	srv, err := server.New(cfg, svc)
	if err != nil {
		slog.Error("Failed to create server", err)
	}
	if err := srv.Run(); err != nil {
		slog.Error("Failed to run server", err)
	}

	slog.Info("Server Ended.")
}

func newLogger(debug bool) *slog.Logger {
	var logLevel slog.Level
	if debug {
		logLevel = slog.LevelDebug
	} else {
		logLevel = slog.LevelInfo
	}
	return slog.New(slog.NewTextHandler(
		os.Stdout,
		&slog.HandlerOptions{
			AddSource: false,
			Level:     logLevel,
			// Fuck! Have to define handler if I want not to display the keys..
			ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
				if a.Key == slog.TimeKey {
					t := a.Value.Time()
					local := t.Local().Format("2006-01-02 15:04:05")
					return slog.String("time", local)
				}
				if a.Key == slog.LevelKey {
					return slog.String("level", "["+a.Value.String()+"]")
				}
				return a
			},
		}),
	)
}
