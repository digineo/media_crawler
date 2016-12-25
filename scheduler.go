package main

import (
	"time"
)

// schedules the recrawling of outdated hosts
func scheduler() {
	for range time.NewTicker(time.Minute).C {
		hosts.Recrawl()
	}
}
