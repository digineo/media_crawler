require File.expand_path('../boot', __FILE__)

# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module MediaCrawler
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += %W(#{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Avoid Circular dependencies
    #
    #   - https://github.com/rails/rails/blob/4-0-stable/railties/lib/rails/engine.rb#L459-L468
    #   - https://github.com/rails/rails/blob/4-1-stable/railties/lib/rails/engine.rb#L462-L471
    #
    def eager_load!
      load_paths = config.eager_load_paths[0..-1] # frozen!

      # monkey patch (1): Pfade umsortieren
      pivot   = load_paths.index{|p| p.to_s.ends_with?('app/controllers') }
      m_path  = load_paths.index{|p| p.to_s.ends_with?('app/models') }

      if pivot < m_path
        load_paths[pivot], load_paths[m_path] = load_paths[m_path], load_paths[pivot]
      end

      config.eager_load_paths = load_paths.freeze.each do |load_path|
        glob = if load_path.ends_with?("app/models")
          # monkey patch (2): Unterverzeichnisse ausklammern
          "#{load_path}/*.rb"
        else
          "#{load_path}/**/*.rb"
        end

        matcher = /\A#{Regexp.escape(load_path.to_s)}\/(.*)\.rb\Z/
        Dir.glob(glob).sort.each do |file|
          require_dependency file.sub(matcher, '\1')
        end
      end
    end
  end
end
