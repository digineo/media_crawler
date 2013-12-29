module Server::Locking
  extend ActiveSupport::Concern

  class Locked < ::StandardError; end

  def lock_file
    data_path.join("lock")
  end

  def with_lock
    # ensure directory exists
    lock_file.dirname.mkpath

    File.open(lock_file, "w") do |file|
      if file.flock(File::LOCK_EX | File::LOCK_NB)
        yield
      else
        raise Locked, "Server #{id} already locked"
      end
    end
  end

end
