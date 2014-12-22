module Server::State
  extend ActiveSupport::Concern

  def update_state!
    begin
      Subprocess.run 'ping', '-c', 1, '-w', 5, host_ftp
      self.state = 'up'
    rescue Subprocess::Error
      self.state = 'down'
    end

    save! if state_changed?
    self.state
  end
  
  def up?
    state=='up'
  end
  
  def down?
    state=='down'
  end

end
