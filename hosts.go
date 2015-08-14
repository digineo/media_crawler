package main

import (
	"net"
	"sync"
	"time"
)

type Hosts struct {
	entries map[string]*Host
	wg      sync.WaitGroup
	sync.Mutex
}

func NewHosts() *Hosts {
	return &Hosts{
		entries: make(map[string]*Host),
	}
}

func (hosts *Hosts) Add(address net.IP) bool {
	key := string(address)

	hosts.Lock()
	defer hosts.Unlock()

	if _, ok := hosts.entries[key]; ok {
		return false
	}
	host := CreateHost(address)
	hosts.entries[key] = host
	hosts.wg.Add(1)

	go func() {
		started := time.Now()
		host.Connect()
		host.Login()
		host.Crawl()
		host.Conn.Quit()
		hosts.wg.Done()
		index.DeleteOutdated(host.Address, started)
	}()

	return true
}

func (hosts *Hosts) Remove(address net.IP) {
	key := string(address)

	hosts.Lock()
	defer hosts.Unlock()

	if host, ok := hosts.entries[key]; ok {
		host.Abort()
		delete(hosts.entries, key)
	}
}
