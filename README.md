Media Crawler
=============

A tool for crawling, indexing of media files coming with a powerful search engine.
Actually only FTP servers are supported.



Installation
------------

It is recommended to install 1.9.2 using [RVM](http://beginrescueend.com/).

On Debian/Ubuntu you need to install the following packages:

    (sudo) apt-get install ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8
    (sudo) apt-get install libreadline-ruby1.8 libruby1.8 libopenssl-ruby
    (sudo) apt-get install libxslt-dev libxml2-dev
    (sudo) apt-get install mysql-server libmysqlclient-dev ffmpeg lftp rake rubygems

Clone this repository:

    git clone git@github.com:digineo/media_crawler.git

Now change into the directory and install the required gems:

    cd media_crawler
    (sudo) gem install nokogiri
    (sudo) gem install bundler
    (sudo) bundle install

Then prepare the database. If you want to modify the database configuration, just edit the `config/database.yml`.

    rake db:migrate:reset
    (you may be asked for a root password for mysql; please set one)

Running
-------

First of all you have to start the Solr background process, afterwards the rails process:

    rake sunspot:solr:start
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

(c) 2011 Digineo GmbH, released under the AGPL v3 (GNU Affero General Public License Version 3)

Please feel free to fork and improve this great piece of software :-)

