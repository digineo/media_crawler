package main

import (
	"bufio"
	"encoding/json"
	"log"
	"net"
	"os"
)

type command func(*bufio.Scanner) interface{}

var (
	controlSocket net.Listener

	commands = map[string]command{
		"status": cmdStatus,
		"add":    cmdAdd,
		"remove": cmdRemove,
		"delete": cmdDelete,
	}
)

func newControlSocket() net.Listener {
	log.Println("Starting control socket at", socketPath)
	os.Remove(socketPath)

	var err error
	sock, err := net.Listen("unix", socketPath)
	if err != nil {
		log.Fatal("listen error:", err)
	}

	go func() {
		for {
			if fd, err := sock.Accept(); err != nil {
				log.Fatal("accept error:", err)
			} else {
				go handleControlConn(fd)
			}
		}
	}()
	return sock
}

func handleControlConn(fd net.Conn) {
	defer fd.Close()

	input := bufio.NewScanner(fd)
	output := bufio.NewWriter(fd)
	input.Scan()
	processCommand(input.Text(), input, output)
	output.Flush()
}

func processCommand(name string, input *bufio.Scanner, output *bufio.Writer) {
	var result interface{}

	// lookup function
	if cmd := commands[name]; cmd != nil {
		result = cmd(input)

		// empty result?
		if result == nil {
			result = hash{
				"result": true,
			}
		}
	} else {
		// function not found
		result = hash{
			"error": "unknown command: " + name,
		}
	}

	json.NewEncoder(output).Encode(result)
}

// Returns the worker and cache status as JSON
func cmdStatus(input *bufio.Scanner) interface{} {
	return hash{
		"hosts": hosts.List(),
	}
}

func cmdAdd(input *bufio.Scanner) interface{} {
	for input.Scan() {
		if addr := net.ParseIP(input.Text()); addr != nil {
			hosts.Add(addr)
		}
	}
	return nil
}

// Removes host and stops crawling, but does not delete from the index.
func cmdRemove(input *bufio.Scanner) interface{} {
	for input.Scan() {
		if addr := net.ParseIP(input.Text()); addr != nil {
			hosts.Remove(addr)
		}
	}
	return nil
}

// Deletes host from index
func cmdDelete(input *bufio.Scanner) interface{} {
	for input.Scan() {
		index.DeleteAll(input.Text())
	}
	return nil
}
