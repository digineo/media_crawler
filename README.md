Media Crawler
=============

A tool for crawling, indexing of media files coming with a powerful search engine.
Actually only FTP servers are supported.



Installation
------------

It is recommended to install Ruby 2.0 using [RVM](http://rvm.io/):

    (sudo) curl -sSL https://get.rvm.io | bash -s stable

On Debian/Ubuntu you also need to install the following packages:

    (sudo) apt-get install mongodb ffmpeg lftp

Clone this repository:

    git clone git@github.com:digineo/media_crawler.git

Now change into the directory and install the required gems:

    cd media_crawler
    gem install bundler
    bundle install


Running
-------

Start the rails process with:

    rails s

Now you can reach the media crawler under [http://localhost:3000/](http://localhost:3000/).
To stop all servers just press CTRL + C and execute:

    rake sunspot:solr:stop

Managing servers
----------------

Actually it is only possible to manage servers using the rails shell. You can enter the rails shell by executing `rails c` and leave it by typing `exit` and pressing return.

### Adding servers

    Server.create! :name => 'my local computer', :uri_ftp => '127.0.0.1'

There are some methods in the `app/models/server.rb` to crawl and index your server.
To update the file list of Server #1 execute:

    Server.find(1).update_files

To download and parse alle metadata of Server #1 execute:

    Server.find(1).update_metadata

### Crawling and indexing

Just take a look at the maintenance methods in `app/models/maintenance.rb'. To crawl an index all servers execute:

    Maintenance.update_all


Credits and License
-------------------

(c) 2011-2013 Digineo GmbH, released under the AGPL v3 (GNU Affero General Public License Version 3)

Please feel free to fork and improve this great piece of software :-)

