package main

import (
	"compress/gzip"
	"encoding/csv"
	"os"
	"path"
	"strconv"
)

type CsvWriter struct {
	tmpPath    string
	finalPath  string
	csvWriter  *csv.Writer
	gzipWriter *gzip.Writer
	file       *os.File
}

func NewCsvWriter(path string) (w *CsvWriter, err error) {
	w = &CsvWriter{
		tmpPath:   path + ".tmp",
		finalPath: path,
	}

	w.file, err = os.OpenFile(w.tmpPath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return nil, err
	}

	w.gzipWriter = gzip.NewWriter(w.file)
	w.csvWriter = csv.NewWriter(w.gzipWriter)
	err = w.csvWriter.Write([]string{
		"path",
		"type",
		"count",
		"size",
	})
	return
}

// Writes a CSV line
func (w *CsvWriter) Write(dir string, entry *FileEntry) {
	w.csvWriter.Write([]string{
		path.Join(dir, entry.Name),
		entry.Type,
		strconv.Itoa(int(entry.Count)),
		strconv.FormatUint(entry.Size, 10),
	})
}

// Cancel discards the output and removes the temporary file
func (w *CsvWriter) Cancel() {
	w.file.Close()
	os.Remove(w.tmpPath)
}

// Close closes the writer and moves the temporary file to the destination
func (w *CsvWriter) Close() {
	w.csvWriter.Flush()
	w.gzipWriter.Close()
	w.file.Close()
	os.Rename(w.tmpPath, w.finalPath)
}
