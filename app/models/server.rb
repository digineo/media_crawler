class Server

  SOCKET = Rails.root.join("tmp/sockets/crawler.sock").to_s

  def self.all
    status = self.status['hosts'] rescue []

    list = MediaCrawler::Application.config.data_root.children.map do |path|
      Server.new path, status.find{|s| s["address"] == path.basename.to_s }
    end

    def list.stats
      {
        size:  map(&:size).compact.sum,
        count: map(&:count).compact.sum,
      }
    end
    list
  end

  def self.status
    query("status")
  end

  def self.query(command)
    sock = UNIXSocket.new SOCKET
    sock.write command
    sock.close_write
    JSON.parse sock.read
  end

  attr_reader :path, :status

  def initialize(path, status)
    @name   = path.basename.to_s
    @path   = path
    @status = status || {}
  end

  def add
    self.class.query("add\n#{@name}")
  end

  def size
    index_json.map{|i| i['size'] }.sum rescue @status['total_size']
  end

  def count
    index_json.map{|i| i['count'] }.sum rescue @status['total_count']
  end

  def index_json
    JSON.parse(path.join("index.json").read) || {}
  end

  def address
    path.basename.to_s
  end

  def to_s
    address
  end

  def updated_at
    path.join("entries/index.json").mtime rescue nil
  end

  def has_download?
    path.join("index.csv.gz").exist?
  end

end
