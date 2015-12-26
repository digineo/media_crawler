package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"log"
	"net"
	"os"
)

var controlSocket net.Listener

func newControlSocket() {
	log.Println("Starting control socket at", socketPath)
	os.Remove(socketPath)

	var err error
	controlSocket, err := net.Listen("unix", socketPath)
	if err != nil {
		log.Fatal("listen error:", err)
	}

	go func() {
		for {
			if fd, err := controlSocket.Accept(); err != nil {
				log.Fatal("accept error:", err)
			} else {
				go handleControlConn(fd)
			}
		}
	}()
}

func handleControlConn(fd net.Conn) {
	defer fd.Close()

	input := bufio.NewScanner(fd)
	output := bufio.NewWriter(fd)
	input.Scan()
	if err := processCommand(input.Text(), input, output); err != nil {
		output.WriteString(err.Error() + "\n")
	}
	output.Flush()
}

func processCommand(command string, input *bufio.Scanner, output *bufio.Writer) error {

	var str []byte
	var err error

	switch command {
	case "status":
		str, err = status()
	case "add":
		for input.Scan() {
			if addr := net.ParseIP(input.Text()); addr != nil {
				hosts.Add(addr)
			}
		}
	case "remove":
		for input.Scan() {
			if addr := net.ParseIP(input.Text()); addr != nil {
				hosts.Remove(addr)
			}
		}
	default:
		return errors.New("unknown command: " + command)
	}

	if err != nil {
		return err
	}
	if str != nil {
		_, err = output.Write(str)
		if err != nil {
			return err
		}
		output.Write([]byte("\n"))
	}

	return nil
}

// Returns the worker and cache status as JSON
func status() ([]byte, error) {
	m := make(map[string]interface{})
	m["hosts"] = hosts.List()

	return json.Marshal(m)
}
