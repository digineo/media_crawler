package main

import (
	"flag"
	"log"
	"net"
	"os"
	"time"
)

var (
	cacheRoot string
	hosts     = NewHosts()
)

func main() {
	flag.StringVar(&cacheRoot, "cacheRoot", "", "path to cache root")
	flag.Parse()

	if cacheRoot == "" {
		log.Println("cacheRoot missing", cacheRoot)
		os.Exit(1)
	}

	time.Sleep(time.Second)

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
