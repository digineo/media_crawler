module Server::State
  extend ActiveSupport::Concern

  def update_state!
    `ping -c 1 -w 5 #{host_ftp.shellescape}`
    self.state      = $?.to_i==0 ? 'up' : 'down'
    self.checked_at = Time.now
    save!
  end
  
  def up?
    state=='up'
  end
  
  def down?
    state=='down'
  end

end
