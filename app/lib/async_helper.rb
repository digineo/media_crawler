module AsyncHelper
  extend ActiveSupport::Concern

  # Enqueues a method to run in the background
  def async(method, *args)
    # 1 second in the future should be after finishing the SQL transaction
    self.class.async_in 'record', 1, method.to_s, id.to_s, *args
  end

  module ClassMethods
    def async(method, *args)
      async_in 'class', 1, method.to_s, *args
    end

    # Enqueues a method to run in the future
    def async_in(type, at, *args)
      Sidekiq::Client.push \
        'queue'     => instance_variable_get('@queue') || 'default',
        'class'     => Worker,
        'retry'     => false,
        'args'      => [type, self.to_s, *args]
        #'at'        => (at < 1_000_000_000 ? Time.now + at : at).to_f
    end
  end

end
