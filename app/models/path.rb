require 'elasticsearch/persistence/model'

class Path
  include Elasticsearch::Persistence::Model

  index_name "crawler"

  attribute :server_id, String
  attribute :host,      String
  attribute :type,      String
  attribute :path,      String
  attribute :name,      String
  attribute :size,      Integer
  attribute :objects,   Integer
  attribute :boost,     Float

  def url
    url = "ftp://#{host}#{path}"
    url << "/" unless url.ends_with?("/")
    url << name if name
    url
  end

end
