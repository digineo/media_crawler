package main

import (
	"encoding/base64"
	"fmt"
	elastigo "github.com/mattbaird/elastigo/lib"
	"log"
	"math"
	"sync"
	"time"
)

type hash map[string]interface{}

var index = CreateIndex()

var indexSettings = hash{
	"index": hash{
		"number_of_shards":   1,
		"number_of_replicas": 0,
		"analysis": hash{
			"analyzer": hash{
				"path": hash{
					"tokenizer": "path_hierarchy",
				},
				"simplify": hash{
					"tokenizer": "standard",
					"filter":    []string{"lowercase", "asciifolding", "snowball"},
				},
				"filename": hash{
					"tokenizer": "filename",
					"filter":    []string{"lowercase", "edge_ngram"},
				},
			},
			"tokenizer": hash{
				"filename": hash{
					"pattern": "[^\\p{L}\\d]+",
					"type":    "pattern",
				},
			},
			"filter": hash{
				"edge_ngram": hash{
					"side":     "front",
					"max_gram": 20,
					"min_gram": 1,
					"type":     "edgeNGram",
				},
			},
		},
	},
}

var mappingOptions = elastigo.MappingOptions{
	Properties: hash{
		"type": hash{
			"type":  "string",
			"store": true,
		},
		"path": hash{
			"type":     "string",
			"analyzer": "path",
			"store":    true,
		},
		"name": hash{
			"type":     "string",
			"analyzer": "filename",
			"store":    true,
		},
		"size": hash{
			"type":  "long",
			"store": true,
		},
		"objects": hash{
			"type":  "integer",
			"store": true,
		},
		"server_id": hash{
			"type": "integer",
		},
		"created": hash{
			"type":   "date",
			"format": "dateOptionalTime",
		},
	},
}

type Entry struct {
	//Created  time.Time `json:"created"`
	Address string  `json:"host"`
	Type    string  `json:"type"`
	Path    string  `json:"path"`
	Name    string  `json:"name"`
	Size    uint64  `json:"size"`
	Objects int     `json:"objects"`
	Boost   float32 `json:"boost"`
}

type Index struct {
	Name    string
	Mapping string
	Channel chan *Entry
	Conn    *elastigo.Conn
	wg      sync.WaitGroup
}

func CreateIndex() *Index {
	index := &Index{
		Name:    "crawler",
		Mapping: "path",
		Channel: make(chan *Entry, 100),
		Conn:    elastigo.NewConn(),
	}
	index.Conn.Domain = "localhost"
	return index
}

func (index *Index) DropAndCreate() {
	index.Conn.DeleteIndex(index.Name)

	_, err := index.Conn.CreateIndexWithSettings(index.Name, indexSettings)
	if err != nil {
		panic(err)
	}

	err = index.Conn.PutMapping(index.Name, index.Mapping, Entry{}, mappingOptions)
	if err != nil {
		panic(err)
	}

}

// Enqueue the entry
func (index *Index) addToIndex(address string, folder string, entry *FileEntry) {
	var boost float32
	if entry.Size > 0 {
		boost = float32(math.Log(float64(entry.Size)))
	}
	index.Channel <- &Entry{
		Address: address,
		Path:    folder,
		Type:    entry.Type,
		Name:    entry.Name,
		Size:    entry.Size,
		Objects: entry.Count,
		Boost:   boost,
	}
}

func (index *Index) indexWorker() {
	index.wg.Add(1)
	for entry := range index.Channel {
		index.CreateEntry(entry)
	}
	index.wg.Done()
}

// Look up a FileEntry by filename and size and
func (index *Index) CreateEntry(entry *Entry) {
	docId := base64.URLEncoding.EncodeToString([]byte(fmt.Sprintf("%s/%s/%s", entry.Address, entry.Path, entry.Name)))
	_, err := index.Conn.Index(index.Name, index.Mapping, docId, nil, entry)

	if err != nil {
		panic(err)
	}

	return
}

func (index *Index) DeleteAll(host string) {
	index.DeleteByBoolFilter([]hash{
		hash{
			"term": hash{
				"host": host,
			},
		},
	})
}

func (index *Index) DeleteOutdated(host string, before time.Time) {
	index.DeleteByBoolFilter([]hash{
		hash{
			"term": hash{
				"host": host,
			},
		},
		hash{
			"range": hash{
				"updated_at": hash{
					"lt": before,
				},
			},
		},
	})
}

// Look up a FileEntry by filename and size and
func (index *Index) DeleteByBoolFilter(filter []hash) {
	query := hash{
		"query": hash{
			"filtered": hash{
				"filter": hash{
					"bool": hash{
						"must": filter,
					},
				},
			},
		},
	}
	scroll := hash{"scroll": "1m"}

	result, err := index.Conn.Search(index.Name, "", scroll, query)
	scrollId := result.ScrollId

	for err == nil && result.Hits.Len() > 0 {
		for _, hit := range result.Hits.Hits {
			index.Conn.Delete(index.Name, hit.Type, hit.Id, nil)
		}
		result, err = index.Conn.Scroll(scroll, scrollId)
	}

	if err != nil {
		log.Println(err)
	}
}
