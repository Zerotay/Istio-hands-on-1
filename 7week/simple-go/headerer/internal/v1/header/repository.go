package header

import "headerer/internal/v1/entity"

type Repository interface {
	Get(key string) (entity.Header, error)
	Set(key string, h entity.Header) error
	List() ([]entity.Header, error)
}
