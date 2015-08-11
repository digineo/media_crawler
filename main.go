package main

import (
	"log"
	"os"
)

func main() {

	err := initializeIndex()
	if err != nil {
		log.Println(err)
	} else {
		log.Print("Index angelegt")
	}

	ftp := CreateFtp(os.Args[1])

	log.Println("Connecting to", ftp.Url)
	ftp.ConnectLoop()
	ftp.LoginLoop()
	defer ftp.Conn.Quit()

	ftp.StartCrawling()
}
