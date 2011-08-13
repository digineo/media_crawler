module Maintenance
  
  def self.update_all
    Server.order("files_updated_at").find_each do |server|
      server.update_state!
      if server.up?
        
        server.update_files && server.update_metadata
      end
    end
  end
  
  def self.update_files
    Server.order("files_updated_at").find_each(&:update_files)
  end
  
  def self.update_metadata
    Server.order("metadata_updated_at").find_each(&:update_metadata)
  end
  
  def self.update_state
    Server.find_each(&:update_state!)
  end
  
end