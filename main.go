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
	hosts     = NewHostmap()
)

func main() {
	flag.StringVar(&cacheRoot, "cacheRoot", "", "path to cache root")
	flag.Parse()

	if cacheRoot == "" {
		log.Println("cacheRoot missing", cacheRoot)
		os.Exit(1)
	}

	time.Sleep(time.Second)

	addHost(1, net.ParseIP(flag.Args()[0]))
	go index.indexWorker()

	hosts.Wait()

	close(index.Channel)
	index.wg.Wait()

}
