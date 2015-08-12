package main

import (
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
	ServerId int `json:"server_id"`
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
	index.Conn.DeleteIndex(index.Name)

	_, err := index.Conn.CreateIndexWithSettings(index.Name, indexSettings)
	if err != nil {
		panic(err)
	}

	err = index.Conn.PutMapping(index.Name, index.Mapping, Entry{}, mappingOptions)
	if err != nil {
		panic(err)
	}

	return index
}

// Enqueue the entry
func (index *Index) addToIndex(serverId int, address string, folder string, entry *FileEntry) {
	var boost float32
	if entry.Size > 0 {
		boost = float32(math.Log(float64(entry.Size)))
	}
	index.Channel <- &Entry{
		ServerId: serverId,
		Address:  address,
		Path:     folder,
		Type:     entry.Type,
		Name:     entry.Name,
		Size:     entry.Size,
		Objects:  entry.Count,
		Boost:    boost,
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
	index.DeleteByBoolFilter([]hash{
		hash{
			"term": hash{
				"server_id": entry.ServerId,
			},
		},
		hash{
			"term": hash{
				"path": entry.Path,
			},
		},
		hash{
			"term": hash{
				"name": entry.Name,
			},
		},
	})

	_, err := index.Conn.Index(index.Name, index.Mapping, "", nil, entry)

	if err != nil {
		panic(err)
	}

	return
}

func (index *Index) DeleteOutdated(serverId int, before time.Time) {
	index.DeleteByBoolFilter([]hash{
		hash{
			"term": hash{
				"ServerId": serverId,
			},
		},
		hash{
			"range": hash{
				"Created": hash{
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

	_, err := index.Conn.DeleteByQuery([]string{index.Name}, []string{index.Mapping}, nil, query)

	if err != nil {
		log.Panic(err)
	}
}
