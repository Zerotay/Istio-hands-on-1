package main

import (
	"bufio"
	"context"
	"fmt"
	"golang.org/x/sys/unix"
	"log"
	"net"
	"os"
	"os/signal"
	"runtime"
	"sync"
	"time"
)

const (
	testNamespace = "test"
	addr          = ":3000"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	wg := &sync.WaitGroup{}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, unix.SIGINT, unix.SIGTERM)

	wg.Add(1)
	// This serves the same addr, but in the other net ns.
	// It also calls listenAndAccept internally.
	go handleOtherNamespace(ctx, wg)

	wg.Add(1)
	go listenAndAccept(ctx, wg)

	<-sigs
	fmt.Println("Shutting down")

	cancel()
	wg.Wait()
	fmt.Println("Bye!")
}

func handleOtherNamespace(ctx context.Context, wg *sync.WaitGroup) {
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	fd, err := os.Open("/var/run/netns/" + testNamespace)
	if err != nil {
		log.Fatalf("Net namespace doesn't exists: %v", err)
	}
	defer fd.Close()
	if err := unix.Setns(int(fd.Fd()), unix.CLONE_NEWNET); err != nil {
		log.Fatalf("Failed to set namespace to netns: %v", err)
	}

	fmt.Printf("Ready to serve in netns %s\n", testNamespace)
	listenAndAccept(ctx, wg)
}

func listenAndAccept(ctx context.Context, wg *sync.WaitGroup) {
	defer wg.Done()

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}
	defer ln.Close()
	fmt.Printf("Listening on port %s\n", addr)

	for {
		ln.(*net.TCPListener).SetDeadline(time.Now().Add(time.Second))
		conn, err := ln.Accept()
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				select {
				case <-ctx.Done():
					return
				default:
					continue
				}
			}
			fmt.Printf("Failed to accept connection: %v", err)
			continue
		}
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	fmt.Printf("New connection from %v\n", conn.RemoteAddr())

	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		line := scanner.Text()
		fmt.Println(line)
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "reading standard input:", err)
	}
}
