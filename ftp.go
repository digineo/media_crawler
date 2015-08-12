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
	"strconv"
	"sync"
	"time"
)

const (
	cacheFilename = "index.json" // folders with this name are ignored
)

type Host struct {
	Id       int
	Address  string
	Running  bool
	State    string
	Error    error
	Conn     *ftp.ServerConn
	cacheDir string

	mt sync.Mutex
}

// Stuct for the JSON dump
type FileEntry struct {
	Name     string `json:"name"`
	Size     uint64 `json:"size"`
	Count    int    `json:"count,omitempty"`
	Type     string `json:"type"`
	children []*FileEntry
}

func CreateHost(id int, address net.IP) (ftp *Host) {
	ftp = &Host{
		Id:       id,
		Address:  address.String(),
		cacheDir: path.Join(cacheRoot, strconv.Itoa(id)),
	}

	return
}

func (host *Host) SetState(state string) {
	log.Print(state)
	host.State = state
}

func (host *Host) Abort() {
	host.Running = false
}

// Try to connect as long as the server is not obsolete
// This function does not return errors as high-load FTPs
// do likely need hundreds of connection retries
func (host *Host) Connect() {
	host.Running = true

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
			break
		}

		host.SetState(fmt.Sprintf("logging in (attempt %d failed)"))
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

	host.mt.Lock()
	host.crawlDirectoryRecursive(pwd)
	host.mt.Unlock()

	host.SetState("crawling finished")

	return
}

func (host *Host) crawlDirectoryRecursive(dir string) *FileEntry {
	host.SetState(fmt.Sprintf("crawling: %s", dir))

	children := make([]*FileEntry, 0, 128)
	subdirs := make(map[string]bool)
	result := &FileEntry{
		Name: filepath.Base(dir),
		Type: "dir",
	}

	var list []*ftp.Entry
	list, host.Error = host.Conn.List(dir)

	if host.Error != nil {
		log.Println(host.Error)
	}

	// Iterate over directory content
	for _, file := range list {
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
			children = append(children, entry)
		}

		// Add to index
		if entry != nil {
			index.addToIndex(host.Id, host.Address, dir, entry)
		}
	}

	// Create output directory
	outputDir := path.Join(host.cacheDir, dir)
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

	return result
}
