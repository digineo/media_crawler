source 'https://rubygems.org'

gem 'rails',   '~> 4.2.0'
gem 'mongoid', '~> 4.0.0'

gem 'streamio-ffmpeg',
#  github: 'digineo/streamio-ffmpeg'
  path: '../streamio-ffmpeg'

gem 'jquery-rails'
gem 'turbolinks'
gem 'rails-timeago',       '~> 2.0'
gem 'haml-rails'
gem 'sass-rails',          '~> 4.0'
gem 'bootstrap-sass',      '~> 3.2'

gem 'elasticsearch',       '~> 1.0.6'
gem 'elasticsearch-rails'
gem 'elasticsearch-model'
gem 'kaminari'

gem 'uglifier',     '>= 2.6'
gem 'coffee-rails', '~> 4.1'
gem 'therubyracer',  platforms: :ruby

# Background Jobs
gem 'sidekiq', '~> 3.3.0'
gem 'sinatra', require: nil, group: [:development, :production]

group :development, :test do
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'factory_girl_rails'
end

group :development do
  gem 'pry-rails'
  gem 'quiet_assets'
end

group :test do
  gem 'rspec-its', '~> 1.0.1'
  gem 'shoulda-matchers'
end
