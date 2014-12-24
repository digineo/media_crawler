class DirectoryGrapher

  File = Struct.new(:name, :size)

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

  def write(output_dir)
    @root.write_recursivly output_dir
  end

end
