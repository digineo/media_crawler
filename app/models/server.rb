class Server

  SOCKET = Rails.root.join("tmp/sockets/control.sock").to_s

  def self.all
    status = self.status['hosts'] rescue {"hosts" => []}

    MediaCrawler::Application.config.public_data_root.join("servers").children.map do |path|
      Server.new path, status.find{|s| s["address"] == path.basename.to_s }
    end
  end

  def self.status
    sock = UNIXSocket.new SOCKET
    sock.write "status"
    sock.close_write
    JSON.parse sock.read
  end

  attr_reader :path, :status

  def initialize(path, status)
    @path   = path
    @status = status
  end

  def address
    path.basename.to_s
  end

  def to_s
    address
  end

  def updated_at
    path.join("index.json").mtime rescue nil
  end

end
