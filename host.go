package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"os"
	"path"
	"path/filepath"
	"syscall"
	"time"

	"github.com/jlaffaye/ftp"
)

const (
	cacheFilename        = "index.json" // folders with this name are ignored
	entryTypeFile        = "file"
	entryTypeDirectory   = "dir"
	connectRetryInterval = time.Second * 2
	loginRetryInterval   = time.Second * 2
)

type Host struct {
	Started    time.Time `json:"started"`
	Finished   time.Time `json:"finished"`
	Address    string    `json:"address"` // IP address
	Running    bool      `json:"running"`
	State      string    `json:"state"`
	Error      error     `json:"error"`       // the last FTP error
	TotalCount uint      `json:"total_count"` // total number of files
	TotalSize  uint64    `json:"total_size"`  // total size of files
	conn       *ftp.ServerConn
}

// Stuct for the JSON dump
type FileEntry struct {
	Name     string `json:"name"`
	Size     uint64 `json:"size"`
	Count    uint   `json:"count,omitempty"`
	Type     string `json:"type"`
	children []*FileEntry
}

func CreateHost(address net.IP) *Host {
	return &Host{
		Address: address.String(),
	}
}

func (host *Host) cacheDir() string {
	return path.Join(cacheRoot, host.Address)
}

func (host *Host) setState(format string, a ...interface{}) {
	state := fmt.Sprintf(format, a...)
	log.Printf("[%s]: %s", host.Address, state)
	host.State = state
}

func (host *Host) incrementTotal(size uint64) {
	host.TotalCount++
	host.TotalSize += size
}

// Abort aborts a running crawl.
func (host *Host) Abort() {
	host.Running = false
}

func (host *Host) Run() bool {
	if host.Running {
		return false
	}

	host.TotalCount = 0
	host.TotalSize = 0
	host.Running = true
	hosts.wg.Add(1)

	go func() {
		host.run()
		hosts.wg.Done()
	}()

	return true
}

func (host *Host) run() {
	host.Error = nil
	host.Started = time.Now()

	host.Connect()
	host.Login()
	host.Crawl()
	host.conn.Quit()

	index.DeleteOutdated(host.Address, host.Started)

	host.Finished = time.Now()
	host.Running = false
}

// Connect tries to connect as long as the server is not obsolete
// This function does not return errors as high-load FTPs
// do likely need hundreds of connection retries
func (host *Host) Connect() {
	attempt := 1

	for host.Running {
		host.setState("connecting (attempt %d)", attempt)

		host.conn, host.Error = ftp.Connect(net.JoinHostPort(host.Address, "21"))
		if host.Error == nil {
			break
		}

		host.setState("connecting (attempt %d failed)", attempt)
		time.Sleep(connectRetryInterval)
		attempt++
	}
}

// Login tries to login as anonymous user.
// This function does not return on errors as high-load FTPs
// do likely need hundreds of login retries.
func (host *Host) Login() {
	attempt := 1

	for host.Running {
		host.setState("logging in (attempt %d)", attempt)

		host.Error = host.conn.Login("anonymous", "anonymous")

		if host.Error == nil {
			host.setState("login successful")
			break
		}

		if host.Error == syscall.EPIPE {
			return
		}

		host.setState("logging in (attempt %d failed)", attempt)
		time.Sleep(loginRetryInterval)
		attempt++
	}
}

// Recursively walk through all directories
func (host *Host) Crawl() {
	var pwd string
	pwd, host.Error = host.conn.CurrentDir()
	if host.Error != nil {
		return
	}

	host.crawlDirectoryRecursive(pwd)
	host.setState("crawling finished")

	return
}

// Store entries to cache and index
func storeEntries(host *Host, dir string, children []*FileEntry) {
	subdirs := make(map[string]bool)

	// Iterate over children
	for _, entry := range children {
		if entry.Type == entryTypeDirectory {
			subdirs[entry.Name] = true
		}
		index.addToIndex(host.Address, dir, entry)
	}

	// Create output directory
	outputDir := path.Join(host.cacheDir(), dir)
	os.MkdirAll(outputDir, 0755)

	// Save JSON
	data, _ := json.Marshal(children)
	if err := ioutil.WriteFile(path.Join(outputDir, cacheFilename), data, 0644); err != nil {
		panic(err)
	}

	// Remove subdirectories that does not exist on the server any more
	files, _ := ioutil.ReadDir(outputDir)
	for _, file := range files {
		name := file.Name()
		if _, ok := subdirs[name]; !ok && name != cacheFilename {
			os.RemoveAll(path.Join(outputDir, name))
		}
	}
}

func (host *Host) crawlDirectoryRecursive(dir string) (result *FileEntry) {
	host.setState("crawling: %s", dir)

	children := make([]*FileEntry, 0, 128)
	result = &FileEntry{
		Name: filepath.Base(dir),
		Type: entryTypeDirectory,
	}

	var list []*ftp.Entry
	list, host.Error = host.conn.List(dir)

	if host.Error != nil {
		host.setState("crawling failed: %s", host.Error)
	}

	// Iterate over directory content
	for _, file := range list {
		if !host.Running {
			return
		}

		ff := path.Join(dir, file.Name)

		switch file.Type {
		case ftp.EntryTypeFolder:
			if file.Name == "." || file.Name == ".." {
				continue
			}
			if file.Name != cacheFilename {
				entry := host.crawlDirectoryRecursive(ff)
				result.Count += entry.Count
				result.Size += entry.Size
				children = append(children, entry)
			}

		case ftp.EntryTypeFile:
			entry := &FileEntry{
				Name: filepath.Base(ff),
				Size: file.Size,
				Type: entryTypeFile,
			}
			result.Count++
			result.Size += file.Size
			host.incrementTotal(entry.Size)
			children = append(children, entry)
		}
	}

	storeEntries(host, dir, children)

	return
}
