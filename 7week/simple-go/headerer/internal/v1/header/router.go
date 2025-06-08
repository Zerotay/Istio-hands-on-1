package header

import (
	"net/http"
)

func Register(mux *http.ServeMux, svc Service) {
	c := handler{svc}
	mux.HandleFunc("/get/", c.get)
	mux.HandleFunc("/set/", c.set)
	mux.HandleFunc("/", c.execute)
}
