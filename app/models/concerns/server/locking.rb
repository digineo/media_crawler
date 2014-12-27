module Server::Locking
  extend ActiveSupport::Concern

  class Locked < ::StandardError; end

  def with_lock(name)
    # ensure directory exists
    data_path.mkpath

    File.open(data_path.join("#{name}.lock"), "w") do |file|
      if file.flock(File::LOCK_EX | File::LOCK_NB)
        yield
      else
        raise Locked, "Server #{id} already locked for #{name}"
      end
    end
  end

end
