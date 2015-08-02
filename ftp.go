package main

import (
	"encoding/json"
	"github.com/jlaffaye/ftp"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"sync"
	"time"
)

const (
	cacheFilename = "index.json" // folders with this name are ignored
	cacheDir      = "cache"
)

type Ftp struct {
	Url      string
	Obsolete bool
	Running  bool
	Conn     *ftp.ServerConn
	cacheDir string

	mt sync.Mutex
}

type FileEntry struct {
	Name     string `json:"name"`
	Size     uint64 `json:"size"`
	Count    int    `json:"count,omitempty"`
	children []*FileEntry
}

func main() {
	ftp := CreateFtp(os.Args[1])

	log.Println("Connecting to", ftp.Url)
	ftp.ConnectLoop()
	ftp.LoginLoop()
	defer ftp.Conn.Quit()

	ftp.StartCrawling()
}

func CreateFtp(url string) (ftp *Ftp) {
	ftp = &Ftp{
		Url:      url,
		cacheDir: path.Join(cacheDir, url),
	}

	return
}

// Try to connect as long as the server is not obsolete
// This function does not return errors as high-load FTPs
// do likely need hundreds of connection retries
func (elem *Ftp) ConnectLoop() {
	for !elem.Obsolete {
		conn, err := ftp.Connect(elem.Url)
		if err == nil {
			elem.Conn = conn
			break
		}

		log.Println(err)
		time.Sleep(2 * time.Second)
	}
}

// Try to login as anonymous user
// This function does not return errors as high-load FTPs
// do likely need hundreds of login retries
func (elem *Ftp) LoginLoop() {
	for !elem.Obsolete {
		err := elem.Conn.Login("anonymous", "anonymous")
		if err == nil {
			break
		}

		log.Println(err)
		time.Sleep(2 * time.Second)
	}
}

// Recursively walk through all directories
func (elem *Ftp) StartCrawling() (err error) {
	pwd, err := elem.Conn.CurrentDir()
	if err != nil {
		return
	}

	elem.mt.Lock()
	elem.crawlDirectoryRecursive(pwd)
	elem.mt.Unlock()

	return
}

func (elem *Ftp) crawlDirectoryRecursive(dir string) *FileEntry {
	children := make([]*FileEntry, 0, 128)
	subdirs := make(map[string]bool)
	result := &FileEntry{
		Name: filepath.Base(dir),
	}

	list, err := elem.Conn.List(dir)

	if err != nil {
		log.Println(err)
	}

	for _, file := range list {
		ff := path.Join(dir, file.Name)

		switch file.Type {
		case ftp.EntryTypeFolder:
			if file.Name != cacheFilename {
				entry := elem.crawlDirectoryRecursive(ff)
				result.Count += entry.Count
				result.Size += entry.Size
				children = append(children, entry)
				subdirs[file.Name] = true
			}

		case ftp.EntryTypeFile:
			entry := &FileEntry{
				Name: filepath.Base(ff),
				Size: file.Size,
			}
			result.Count += 1
			result.Size += file.Size
			children = append(children, entry)
		}
	}

	// Create output directory
	outputDir := path.Join(elem.cacheDir, dir)
	os.MkdirAll(outputDir, 0755)

	// Save JSON
	data, _ := json.Marshal(children)
	if err = ioutil.WriteFile(path.Join(outputDir, cacheFilename), data, 0644); err != nil {
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
