package sample_go

import (
	"context"
	"fmt"
	cluster "github.com/envoyproxy/go-control-plane/envoy/service/cluster/v3"
	discovery "github.com/envoyproxy/go-control-plane/envoy/service/discovery/v3"
	endpoint "github.com/envoyproxy/go-control-plane/envoy/service/endpoint/v3"
	listener "github.com/envoyproxy/go-control-plane/envoy/service/listener/v3"
	route "github.com/envoyproxy/go-control-plane/envoy/service/route/v3"
	runtime "github.com/envoyproxy/go-control-plane/envoy/service/runtime/v3"
	secret "github.com/envoyproxy/go-control-plane/envoy/service/secret/v3"
	"github.com/envoyproxy/go-control-plane/pkg/cache/v3"
	"github.com/envoyproxy/go-control-plane/pkg/test/v3"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"log"
	"net"
	"time"
)
import "github.com/envoyproxy/go-control-plane/pkg/server/v3"

const (
	grpcKeepaliveTime        = 30 * time.Second
	grpcKeepaliveTimeout     = 5 * time.Second
	grpcMaxConcurrentStreams = 1000000
	grpcKeepaliveMinTime     = 30 * time.Second
)

type Server struct {
	xdsserver server.Server
}

func NewServer(ctx context.Context, cache cache.Cache, cb *test.Callbacks) *Server {
	srv := server.NewServer(ctx, cache, cb)
	return &Server{srv}
}

func (s *Server) registerServer(grpcServer *grpc.Server) {
	discovery.RegisterAggregatedDiscoveryServiceServer(grpcServer, s.xdsserver)
	endpoint.RegisterEndpointDiscoveryServiceServer(grpcServer, s.xdsserver)
	cluster.RegisterClusterDiscoveryServiceServer(grpcServer, s.xdsserver)
	route.RegisterRouteDiscoveryServiceServer(grpcServer, s.xdsserver)
	secret.RegisterSecretDiscoveryServiceServer(grpcServer, s.xdsserver)
	listener.RegisterListenerDiscoveryServiceServer(grpcServer, s.xdsserver)
	runtime.RegisterRuntimeDiscoveryServiceServer(grpcServer, s.xdsserver)
}

func (s *Server) Run(port uint) {
	var grpcOptions []grpc.ServerOption
	grpcOptions = append(
		grpcOptions,
		grpc.MaxConcurrentStreams(grpcMaxConcurrentStreams),
		grpc.MaxConcurrentStreams(grpcMaxConcurrentStreams),
		grpc.KeepaliveParams(keepalive.ServerParameters{
			Time:    grpcKeepaliveTime,
			Timeout: grpcKeepaliveTimeout,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             grpcKeepaliveTime,
			PermitWithoutStream: true,
		}),
	)
	grpcServer := grpc.NewServer(grpcOptions...)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Fatal(err)
	}

	s.registerServer(grpcServer)

	log.Printf("Starting gRPC server on port %d", port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Println(err)
	}
}

func registerServer(grpcServer *grpc.Server, server server.Server) {
	discovery.RegisterAggregatedDiscoveryServiceServer(grpcServer, server)
	endpoint.RegisterEndpointDiscoveryServiceServer(grpcServer, server)
	cluster.RegisterClusterDiscoveryServiceServer(grpcServer, server)
	route.RegisterRouteDiscoveryServiceServer(grpcServer, server)
	secret.RegisterSecretDiscoveryServiceServer(grpcServer, server)
	listener.RegisterListenerDiscoveryServiceServer(grpcServer, server)
	runtime.RegisterRuntimeDiscoveryServiceServer(grpcServer, server)
}

func RunServer(srv server.Server, port uint) {
	var grpcOptions []grpc.ServerOption
	grpcOptions = append(
		grpcOptions,
		grpc.MaxConcurrentStreams(grpcMaxConcurrentStreams),
		grpc.MaxConcurrentStreams(grpcMaxConcurrentStreams),
		grpc.KeepaliveParams(keepalive.ServerParameters{
			Time:    grpcKeepaliveMinTime,
			Timeout: grpcKeepaliveTimeout,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             grpcKeepaliveMinTime,
			PermitWithoutStream: true,
		}),
	)

	grpcServer := grpc.NewServer(grpcOptions...)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Fatal(err)
	}

	registerServer(grpcServer, srv)
	log.Printf("Starting gRPC server on port %d", port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Println(err)
	}

}
