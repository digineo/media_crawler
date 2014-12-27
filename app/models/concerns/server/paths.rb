module Server::Paths
  extend ActiveSupport::Concern

  def update_paths
    with_lock :paths do
      delete_paths
      insert_paths
    end
  end

  def delete_paths
    # Remove all entries
    Path.gateway.client.delete_by_query index: 'paths', body: {
      query: {
        filtered: {
          filter: {
            term:  { server_id: id.to_s },
          }
        }
      }
    }
  end

  # Insert paths into the database and removes old entries
  def insert_paths
    # Insert a new entry
    create_path = ->(path, name, entry){
      attr = {
        server_id: self.id,
        host:      self.host_ftp,
        path:      path,
        name:      name,
        type:      DirectoryGrapher::Dir===entry ? 'dir' : 'file',
        size:      entry.size,
        boost:     Math.log(entry.size)
      }
      attr[:objects] = entry.count if Dir === entry
      Path.create attr
    }

    directory_graph.walk Pathname.new("/") do |pathname, entry|
      case entry
      when DirectoryGrapher::File
        create_path.call pathname.to_s, entry.name, entry
      when DirectoryGrapher::Dir
        if pathname.to_s == "/" # Root directory?
          create_path.call pathname.to_s, nil, entry
        else
          create_path.call *pathname.split.map(&:to_s), entry
        end
      else
        raise "invalid entry: #{entry}"
      end
    end
  end


end
