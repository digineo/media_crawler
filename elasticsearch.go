package main

import (
	elastigo "github.com/mattbaird/elastigo/lib"
)

type Entry struct {
	Type    string
	Path    string
	Name    string
	Size    uint64
	Objects uint64
}

type hash map[string]interface{}

func initializeIndex() (err error) {
	conn := elastigo.NewConn()
	conn.Domain = "localhost"
	conn.DeleteIndex("ftp")

	_, err = conn.CreateIndexWithSettings("ftp", hash{
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
	})
	if err != nil {
		return
	}

	err = conn.PutMapping("ftp", "entry", Entry{}, elastigo.MappingOptions{
		Properties: hash{
			"Type": hash{
				"type": "string",
			},
			"Path": hash{
				"type":     "string",
				"analyzer": "path",
			},
			"Name": hash{
				"type":     "string",
				"analyzer": "filename",
			},
			"Size": hash{
				"type": "long",
			},
			"Objects": hash{
				"type": "integer",
			},
		},
	})
	if err != nil {
		return
	}

	return nil
}
