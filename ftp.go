package main

import (
	"encoding/json"
	"fmt"
	"github.com/jlaffaye/ftp"
	"io/ioutil"
	"log"
	"net"
	"os"
	"path"
	"path/filepath"
	"syscall"
	"time"
)

const (
	cacheFilename = "index.json" // folders with this name are ignored
)

type Host struct {
	Started    time.Time       `json:"started"`
	Finished   time.Time       `json:"finished"`
	Address    string          `json:"address"`
	Running    bool            `json:"running"`
	State      string          `json:"state"`
	Error      error           `json:"error"`
	FilesCount int             `json:"files"`
	Conn       *ftp.ServerConn `json:"-"`
}

// Stuct for the JSON dump
type FileEntry struct {
	Name     string `json:"name"`
	Size     uint64 `json:"size"`
	Count    int    `json:"count,omitempty"`
	Type     string `json:"type"`
	children []*FileEntry
}

func CreateHost(address net.IP) *Host {
	host := &Host{
		Address: address.String(),
		Running: true,
	}
	return host
}

func (host *Host) CacheDir() string {
	return path.Join(cacheRoot, host.Address)
}

func (host *Host) SetState(state string) {
	log.Println(host.Address, state)
	host.State = state
}

func (host *Host) Abort() {
	host.Running = false
}

func (host *Host) Run() {
	host.Running = true
	hosts.wg.Add(1)

	go func() {
		host.Error = nil
		host.Started = time.Now()

		host.Connect()
		host.Login()
		host.Crawl()
		host.Conn.Quit()

		index.DeleteOutdated(host.Address, host.Started)

		host.Finished = time.Now()

		host.Running = false
		hosts.wg.Done()
	}()
}

// Try to connect as long as the server is not obsolete
// This function does not return errors as high-load FTPs
// do likely need hundreds of connection retries
func (host *Host) Connect() {
	attempt := 1

	for host.Running {
		host.SetState(fmt.Sprintf("connecting (attempt %d)", attempt))

		host.Conn, host.Error = ftp.Connect(net.JoinHostPort(host.Address, "21"))
		if host.Error == nil {
			break
		}

		host.SetState(fmt.Sprintf("connecting (attempt %d failed)", attempt))
		time.Sleep(2 * time.Second)
		attempt += 1
	}
}

// Try to login as anonymous user
// This function does not return errors as high-load FTPs
// do likely need hundreds of login retries
func (host *Host) Login() {
	attempt := 1

	for host.Running {
		host.SetState(fmt.Sprintf("logging in (attempt %d)", attempt))

		host.Error = host.Conn.Login("anonymous", "anonymous")

		if host.Error == nil {
			host.SetState(fmt.Sprintf("login successful"))
			break
		}

		if host.Error == syscall.EPIPE {
			return
		}

		host.SetState(fmt.Sprintf("logging in (attempt %d failed)", attempt))
		time.Sleep(2 * time.Second)
		attempt += 1
	}
}

// Recursively walk through all directories
func (host *Host) Crawl() {
	var pwd string
	pwd, host.Error = host.Conn.CurrentDir()
	if host.Error != nil {
		return
	}

	host.crawlDirectoryRecursive(pwd)
	host.SetState("crawling finished")

	return
}

func (host *Host) crawlDirectoryRecursive(dir string) (result *FileEntry) {
	host.SetState(fmt.Sprintf("crawling: %s", dir))

	children := make([]*FileEntry, 0, 128)
	subdirs := make(map[string]bool)
	result = &FileEntry{
		Name: filepath.Base(dir),
		Type: "dir",
	}

	var list []*ftp.Entry
	list, host.Error = host.Conn.List(dir)

	if host.Error != nil {
		log.Println(host.Address, host.Error)
	}

	// Iterate over directory content
	for _, file := range list {
		if !host.Running {
			return
		}

		ff := path.Join(dir, file.Name)
		var entry *FileEntry

		switch file.Type {
		case ftp.EntryTypeFolder:
			if file.Name != cacheFilename {
				entry = host.crawlDirectoryRecursive(ff)
				result.Count += entry.Count
				result.Size += entry.Size
				children = append(children, entry)
				subdirs[file.Name] = true
			}

		case ftp.EntryTypeFile:
			entry = &FileEntry{
				Name: filepath.Base(ff),
				Size: file.Size,
				Type: "file",
			}
			result.Count += 1
			result.Size += file.Size
			host.FilesCount += 1
			children = append(children, entry)
		}

		// Add to index
		if entry != nil {
			index.addToIndex(host.Address, dir, entry)
		}
	}

	// Create output directory
	outputDir := path.Join(host.CacheDir(), dir)
	os.MkdirAll(outputDir, 0755)

	// Save JSON
	data, _ := json.Marshal(children)
	if err := ioutil.WriteFile(path.Join(outputDir, cacheFilename), data, 0644); err != nil {
		panic(err)
	}

	// Remove subdirectories that does not exist on the server any more
	files, _ := ioutil.ReadDir(outputDir)
	for _, f := range files {
		name := f.Name()
		if _, ok := subdirs[name]; !ok && name != cacheFilename {
			os.RemoveAll(path.Join(outputDir, name))
		}
	}

	return
}
