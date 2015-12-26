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
	cacheRoot  string
	socketPath string
	hosts      = NewHosts()
)

func main() {
	flag.StringVar(&cacheRoot, "cacheRoot", "", "path to cache root")
	flag.StringVar(&socketPath, "socketPath", "", "path for the unix control socket")
	flag.Parse()
	args := flag.Args()

	if cacheRoot == "" {
		log.Println("cacheRoot missing", cacheRoot)
		os.Exit(1)
	}

	// Start control socket handler
	if socketPath != "" {
		newControlSocket()
		go scheduler()
	}

	// Start index routine
	go index.indexWorker()

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

	if controlSocket != nil {
		controlSocket.Close()
	}

	close(index.Channel)
	index.wg.Wait()
}
