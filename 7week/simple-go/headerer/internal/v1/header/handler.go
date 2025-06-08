package header

import (
	"encoding/json"
	"errors"
	"fmt"
	"headerer/internal/v1/entity"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
)

type handler struct {
	service Service
}

func (h handler) execute(w http.ResponseWriter, r *http.Request) {
	slog.Debug("Handler execute")
	lst, err := h.service.execute()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	for k, v := range lst {
		w.Header().Set(k, v)
	}
	w.WriteHeader(http.StatusOK)
}

func (h handler) set(w http.ResponseWriter, r *http.Request) {
	slog.Debug("Handler set")
	key := r.URL.Path[len("/set/"):]
	if key == "" {
		w.WriteHeader(http.StatusBadRequest)
		if _, err := w.Write([]byte("A Key required")); err != nil {
			slog.Info("Error writing response", err)
		}
		return
	}
	slog.Debug("Get a key from the Path...", slog.Any("Key", key))
	values := strings.Split(r.URL.Query().Get("value"), ",")
	raw := strings.Split(r.URL.Query().Get("weight"), ",")
	weights := make([]int, len(raw))
	sum := 0
	for i, r := range raw {
		n, err := strconv.Atoi(r)
		if err != nil {
			http.Error(w, fmt.Sprintf("Weights need to be an int array"), http.StatusBadRequest)
			return
		}
		weights[i] = n
		sum += n
	}
	if sum != 100 {
		http.Error(w, fmt.Sprintf("Weight must be 100, not %d", sum), http.StatusBadRequest)
		return
	}

	slog.Debug("Query values", slog.Any("Values", values))
	slog.Debug("Query weights", slog.Any("Weights", weights))

	if len(values) == 0 || values[0] == "" {
		http.Error(w, fmt.Sprintf("No values specified"), http.StatusBadRequest)
		return
	}
	if len(values) != len(weights) {
		http.Error(w, fmt.Sprintf("Length must be same, V: %d, W: %d", len(values), len(weights)), http.StatusBadRequest)
		return
	}

	if err := h.service.set(key, entity.Header{
		Key:     key,
		Values:  values,
		Weights: weights,
	}); err != nil {
		http.Error(w, fmt.Sprintf("Error setting the service: %s", err), http.StatusBadRequest)
	}
	w.WriteHeader(http.StatusOK)
	m := fmt.Sprintf("Successfully set the key: %s", key)
	w.Write([]byte(m))
}

func (h handler) get(w http.ResponseWriter, r *http.Request) {
	slog.Debug("Handler get")
	key := r.URL.Path[len("/get/"):]
	if key == "" {
		http.Error(w, fmt.Sprintf("A Key is required"), http.StatusBadRequest)
		return
	}
	header, err := h.service.get(key)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			http.Error(w, fmt.Sprintf("Key '%s' not found", key), http.StatusNotFound)
		} else {
			http.Error(w, fmt.Sprintf("Error Internal Server: %s", err), http.StatusInternalServerError)
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(header); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
