package main

import (
	"net"
	"sync"
	"time"
)

type Hostmap struct {
	entries map[string]*Host
	sync.Mutex
	sync.WaitGroup
}

func NewHostmap() *Hostmap {
	return &Hostmap{
		entries: make(map[string]*Host),
	}
}

func addHost(id int, address net.IP) bool {

	key := string(address)

	hosts.Lock()
	if _, ok := hosts.entries[key]; ok {
		return false
	}
	host := CreateHost(id, address)
	hosts.entries[key] = host
	hosts.Unlock()
	hosts.Add(1)

	go func() {
		started := time.Now()
		host.Connect()
		host.Login()
		host.Crawl()
		host.Conn.Quit()
		hosts.Done()
		index.DeleteOutdated(host.Id, started)
	}()

	return true
}

func cancelHost(address net.IP) {
	if host, ok := hosts.entries[string(address)]; ok {
		host.Abort()
	}
}
