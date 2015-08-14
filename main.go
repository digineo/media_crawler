package main

import (
	"flag"
	"log"
	"net"
	"os"
	"os/signal"
	"runtime"
	"syscall"
)

var (
	cacheRoot  string
	socketPath string
	hosts      = NewHosts()
)

func main() {
	flag.StringVar(&cacheRoot, "cacheRoot", "", "path to cache root")
	flag.StringVar(&socketPath, "socketPath", "", "path for the unix control socket")
	flag.Parse()

	if cacheRoot == "" {
		log.Println("cacheRoot missing", cacheRoot)
		os.Exit(1)
	}

	// Start control socket handler
	if socketPath != "" {
		go controlSocket()
		go scheduler()
	}

	// Configure number of system threads
	gomaxprocs := runtime.NumCPU()
	runtime.GOMAXPROCS(gomaxprocs)
	log.Println("Using", gomaxprocs, "operating system threads")

	// Start index routine
	go index.indexWorker()

	for _, host := range flag.Args() {
		hosts.Add(net.ParseIP(host))
	}

	if socketPath != "" {
		// Wait for SIGINT or SIGTERM
		sigs := make(chan os.Signal, 1)
		signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
		sig := <-sigs
		log.Println("received", sig)
	}

	if len(flag.Args()) > 0 {
		hosts.wg.Wait()
	}

	close(index.Channel)
	index.wg.Wait()
}
