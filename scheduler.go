package main

import (
	"time"
)

var (
	scheduleInterval = time.Hour
)

// schedules outdated hosts
func scheduler() {

	hosts.Lock()
	for _, host := range hosts.entries {
		if !host.Running && time.Since(host.Finished) > scheduleInterval {
			host.Run()
		}
	}
	defer hosts.Unlock()

	time.AfterFunc(time.Minute, scheduler)
}
