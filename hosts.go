package main

import (
	"net"
	"sync"
)

// Hosts is a collection of Hosts with wait group and mutex.
type Hosts struct {
	entries map[string]*Host // map from IP address to Host
	wg      sync.WaitGroup
	sync.RWMutex
}

// NewHosts creates a new list of Hosts.
func NewHosts() *Hosts {
	return &Hosts{
		entries: make(map[string]*Host),
	}
}

// Add adds a host.
// If the host exists and the crawler is not running an new crawl will be enqueued.
func (hosts *Hosts) Add(address net.IP) bool {
	var host *Host
	key := string(address)

	hosts.Lock()
	defer hosts.Unlock()

	// does it already exist?
	if host, ok := hosts.entries[key]; ok {
		// Run again
		return host.Run()
	}

	host = CreateHost(address)
	hosts.entries[key] = host
	host.Run()

	return true
}

// Remove removes a host.
// If the crawler is running it will be aborted.
func (hosts *Hosts) Remove(address net.IP) {
	key := string(address)

	hosts.Lock()
	defer hosts.Unlock()

	if host, ok := hosts.entries[key]; ok {
		host.Abort()
		delete(hosts.entries, key)
	}
}

// List returns a list of all hosts.
func (hosts *Hosts) List() []*Host {
	hosts.RLock()
	defer hosts.RUnlock()

	list := make([]*Host, 0, len(hosts.entries))
	for _, host := range hosts.entries {
		list = append(list, host)
	}
	return list
}

// Requeue enqueues all non-running hosts.
func (hosts *Hosts) Requeue() {
	hosts.Lock()
	defer hosts.Unlock()

	for _, host := range hosts.entries {
		if !host.Running {
			host.Run()
		}
	}
}

func (hosts *Hosts) Recrawl() {
	hosts.Lock()
	for _, host := range hosts.entries {
		host.RecrawlIfDesired()
	}
	hosts.Unlock()
}
