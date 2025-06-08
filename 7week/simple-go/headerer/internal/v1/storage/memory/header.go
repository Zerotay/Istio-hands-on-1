package memory

import (
	"errors"
	"headerer/internal/v1/entity"
	"headerer/internal/v1/header"
	"log/slog"
)

type repository struct {
	//mu sync.RWMutex
	headers map[string]entity.Header
}

func NewRepository() header.Repository {
	return &repository{
		headers: make(map[string]entity.Header),
	}
}

func (r *repository) List() ([]entity.Header, error) {
	//r.mu.RLock()
	//defer r.mu.RUnlock()
	lst := make([]entity.Header, 0, len(r.headers))
	for _, h := range r.headers {
		lst = append(lst, h)
	}
	return lst, nil
}

var ErrNotFound = errors.New("Header not found")

func (r *repository) Get(key string) (entity.Header, error) {
	h, ok := r.headers[key]
	if !ok {
		slog.Debug("Header not found with :", slog.String("key", key))
		return entity.Header{}, ErrNotFound
	}
	return h, nil
}

func (r *repository) Set(k string, h entity.Header) error {
	r.headers[k] = h
	return nil
}
