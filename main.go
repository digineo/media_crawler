package main

import (
	"flag"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
)

var (
	cacheRoot    string
	socketPath   string
	indexWorkers = 2
	hosts        = NewHosts()
)

func main() {
	flag.StringVar(&cacheRoot, "cacheRoot", "", "path to cache root")
	flag.StringVar(&socketPath, "socketPath", "", "path for the unix control socket")
	flag.IntVar(&indexWorkers, "indexWorkers", 2, "Number of index workers")
	flag.Parse()
	args := flag.Args()

	if cacheRoot == "" {
		log.Println("cacheRoot missing", cacheRoot)
		os.Exit(1)
	}

	// Start control socket handler
	if socketPath != "" {
		controlSocket = newControlSocket()
		defer controlSocket.Close()
		go scheduler()
	}

	if indexWorkers > 0 {
		index = newIndex(indexWorkers)
		defer index.close()
	}

	// Any work to do?
	for _, host := range args {
		hosts.Add(net.ParseIP(host))
	}

	if socketPath != "" {
		// Wait for SIGINT or SIGTERM
		sigs := make(chan os.Signal, 1)
		signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
		sig := <-sigs
		log.Println("received", sig)
	}

	if len(args) > 0 {
		hosts.wg.Wait()
	}
}
