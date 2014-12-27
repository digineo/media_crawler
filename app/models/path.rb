require 'elasticsearch/persistence/model'

class Path
  include Elasticsearch::Persistence::Model

  index_name "test_#{index_name}" if Rails.env.test?

  settings index: {
    number_of_shards: 1,
    number_of_replicas: 0,
    analysis: {
      analyzer: {
        path: {
          tokenizer: 'path_hierarchy'
        },
        simplify: {
          tokenizer: 'standard',
          filter: ["lowercase", "asciifolding", "snowball"],
        },
        filename: {
          tokenizer: "filename",
          filter: ["lowercase", "edge_ngram"]
        }
      },
      tokenizer: {
        filename: {
          pattern: "[^\\p{L}\\d]+",
          type: "pattern"
        }
      },
      filter: {
        edge_ngram: {
          side: "front",
          max_gram: 20,
          min_gram: 1,
          type: "edgeNGram"
        }
      }
    }
  }

  attribute :server_id, String
  attribute :host,      String
  attribute :type,      String
  attribute :path,      String, mapping: { analyzer: 'path' }
  attribute :name,      String, mapping: { analyzer: 'filename' }
  attribute :size,      Integer, mapping: { type: 'long' }
  attribute :objects,   Integer, mapping: { type: 'integer' }
  attribute :boost,     Float

  def ==(another)
    self.class === another && another.id == id
  end

  def url
    url = "ftp://#{host}#{path}"
    url << "/" unless url.ends_with?("/")
    url << name if name
    url
  end

end
