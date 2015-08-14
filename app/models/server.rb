class Server

  def self.all
    MediaCrawler::Application.config.public_data_root.join("servers").children.map do |path|
      Server.new(path)
    end
  end

  attr_reader :path

  def initialize(path)
    @path = path
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
