package main

import (
	"time"
)

var (
	recrawlAfter = time.Hour
)

// schedules the recrawling of outdated hosts
func scheduler() {
	hosts.Lock()
	defer hosts.Unlock()

	for _, host := range hosts.entries {
		if !host.Running && time.Since(host.Finished) > recrawlAfter {
			host.Run()
		}
	}

	time.AfterFunc(time.Minute, scheduler)
}
