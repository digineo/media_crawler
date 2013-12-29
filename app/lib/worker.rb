require 'sidekiq/worker'

# Worker for Sidekiq
class Worker
  include Sidekiq::Worker

  def perform(type, clazz, method, *args)
    case type
    when 'class'
      clazz.constantize.send method, *args
    when 'record'
      id = args.shift
      clazz.constantize.find(id).send method, *args
    else
      raise ArgumentError, "unsupported type: #{type}"
    end
  end

end
