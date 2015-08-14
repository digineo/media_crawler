package main

import (
	"net"
	"sync"
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
	host.Run()

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

func (hosts *Hosts) List() []*Host {
	hosts.Lock()
	defer hosts.Unlock()

	list := make([]*Host, 0)
	for _, host := range hosts.entries {
		list = append(list, host)
	}
	return list
}

func (hosts *Hosts) Requeue() {
	hosts.Lock()
	defer hosts.Unlock()

	for _, host := range hosts.entries {
		if !host.Running {
			host.Run()
		}
	}
}
