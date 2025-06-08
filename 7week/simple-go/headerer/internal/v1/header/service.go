package header

import (
	"errors"
	"headerer/internal/v1/entity"
	"log/slog"
	"math/rand"
)

type Selected struct {
	Key string `json:"key"`
	Val string `json:"val"`
}

type Service interface {
	get(key string) (entity.Header, error)
	set(key string, h entity.Header) error
	execute() (map[string]string, error)
	//execute() ([]Selected, error)
}

func NewService(repo Repository) Service {
	return service{
		repository: repo,
	}
}

type service struct {
	repository Repository
}

var ErrNotFound = errors.New("entity not found")

func (s service) get(key string) (entity.Header, error) {
	h, err := s.repository.Get(key)
	if err != nil {
		// Is it clear to return the err from repo?
		slog.Debug("No header found for key: %s", key)
		return entity.Header{}, ErrNotFound
	}
	return h, nil
}

func (s service) set(k string, h entity.Header) error {
	slog.Debug("Service set")
	if err := s.repository.Set(k, h); err != nil {
		slog.Info("Error setting header", h, err)
		return err
	}
	return nil
}

func (s service) execute() (map[string]string, error) {
	//func (s service) execute() ([]Selected, error) {
	lst, err := s.repository.List()
	if err != nil {
		return nil, err
	}
	resp := make(map[string]string)
	//resp := make([]Selected, 0, len(lst))
	for _, l := range lst {
		val := l.Values[pick(l.Weights)]
		resp[l.Key] = val
		//s := Selected{
		//	Key: l.Key,
		//	Val: l.Values[pick(l.Weights)],
		//}
		//fmt.Printf("range %v, selected %v\n", l, s)
		//fmt.Println(s)
		//resp = append(resp, s)
	}
	return resp, nil
}

func pick(weights []int) int {
	r := rand.Intn(100)
	sum := 0
	for i, w := range weights {
		sum += w
		if sum >= r {
			return i
		}
	}
	panic("unreachable")
}
