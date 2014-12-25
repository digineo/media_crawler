RSpec.configure do |config|
  config.before(:each, elasticsearch: true) do
    Path.create_index!(force: true)
  end
end
