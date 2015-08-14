package main

import (
	"flag"
	"log"
	"net"
	"os"
	"runtime"
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
	}

	// Configure number of system threads
	gomaxprocs := runtime.NumCPU()
	runtime.GOMAXPROCS(gomaxprocs)
	log.Println("Using", gomaxprocs, "operating system threads")

	for _, host := range flag.Args() {
		hosts.Add(net.ParseIP(host))
	}

	go index.indexWorker()

	hosts.wg.Wait()

	close(index.Channel)
	index.wg.Wait()

}
