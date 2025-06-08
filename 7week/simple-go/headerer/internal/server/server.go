package server

import (
	"fmt"
	"headerer/internal/config"
	"headerer/internal/v1/header"
	"net/http"
)

type Server struct {
	*http.Server
}

func New(cfg config.Config, svc header.Service) (*Server, error) {
	mux := http.NewServeMux()
	header.Register(mux, svc)
	srv := &Server{
		Server: &http.Server{
			Addr:    fmt.Sprintf(":%d", cfg.Port),
			Handler: mux,
		},
	}
	return srv, nil
}

func (s *Server) Run() error {
	if err := s.ListenAndServe(); err != nil {
		return err
	}
	return nil
}
