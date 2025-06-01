package main

import (
	"context"
	"flag"
	"github.com/envoyproxy/go-control-plane/pkg/test/v3"
	"google.golang.org/grpc"
	sample_go "sample-go"
)

var (
	l sample_go.Logger
	port uint
	nodeID string
)

func init() {
	l = sample_go.Logger{}
	flag.BoolVar(&l.Debug, "debug", false, "debug mode")
	flag.UintVar(&port, "port", 15002, "port to listen")
	flag.StringVar(&nodeID, "nodeID", "test-id", "node id")
}

func main() {
	flag.Parse()

	ctx := context.Background()
	cb := &test.Callbacks{Debug: l.Debug}
	srv := grpc.NewServer(ctx, cb)


}
