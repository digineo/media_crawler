class DirectoryGrapher

  File = Struct.new(:name, :size) do
    def to_s
      name
    end
  end

  class Dir
    def initialize
      @files    = []
      @children = {}
    end

    def add(path, size)
      if path.include?("/")
        top, sub = path.split("/",2)
        if top == "." || top == ".."
          raise ArgumentError, "Illegal path: #{path.inspect}"
        end
        (@children[top] ||= Dir.new).add(sub, size)
      elsif !@children[path] && size > 0
        @files << File.new(path, size)
      end
    end

    # Walks through the tree and calls the given block with
    # Pathname and File/Dir
    def walk(pathname = Pathname.new(""), &block)
      @children.each do |name,child|
        child.walk pathname.join(name), &block
      end
      @files.each do |file|
        yield pathname, file
      end
      yield pathname, self
    end

    def write_recursivly(output_dir)
      write output_dir
      @children.each do |name,child|
        child.write_recursivly output_dir.join(name)
      end
      #rescue Encoding::UndefinedConversionError
    end

    def write(output_dir)
      output_dir.mkpath
      output_dir.join("content.json").open("wb") do |f|
        f.puts to_h.to_json
      end
    end

    # size in kb (recursive)
    def size
      @size ||= @files.map(&:size).sum + @children.values.map(&:size).sum
    end

    # number of entries
    def count
      @count ||= @files.count + @children.values.map(&:count).sum
    end

    def to_h
      {
        children: @children.map{|name,child| {name: name, size: child.size, count: child.count } },
        files:    @files
      }
    end
  end

  def initialize(filelist)
    @root = Dir.new

    filelist.open("r", encoding: "utf-8").each_line do |line|
      if line.valid_encoding?
        size, path = line.strip.split("\t",2)
        
        if path != "." # skip root node
          @root.add path[2..-1], size.to_i
        end
      else
        STDERR.print "invalid encoding: #{line}"
      end
    end
  end

  delegate :walk, to: :@root

  def write(output_dir)
    @root.write_recursivly output_dir
  end

  # Insert paths into the database and removes old entries
  def index!(server)
    # Insert a new entry
    create_path = ->(path, name, entry){
      attr = {
        server_id: server.id,
        host:      server.host_ftp,
        path:      path,
        name:      name,
        size:      entry.size,
        boost:     Math.log(entry.size)
      }
      attr[:objects] = entry.count if Dir === entry
      Path.create attr
    }

    walk Pathname.new("/") do |pathname, entry|
      case entry
      when DirectoryGrapher::File
        create_path.call pathname.to_s, entry.name, entry
      when DirectoryGrapher::Dir
        create_path.call *pathname.split.map(&:to_s), entry
      else
        raise "invalid entry: #{entry}"
      end
      puts "#{entry.class} #{pathname}/#{entry}"
    end
  end

end
