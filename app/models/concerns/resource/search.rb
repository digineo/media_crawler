require 'elasticsearch/model'

module Resource::Search
  extend ActiveSupport::Concern
  
  included do
    include Elasticsearch::Model

    mapping do
      indexes :id,       index: :not_analyzed
      indexes :folder,   analyzer: 'snowball', boost: 2
      indexes :filename, analyzer: 'snowball', boost: 3
      indexes :server_id, type: 'integer'
      indexes :duration,  type: 'integer'
      indexes :audio_codecs,       multiple: true
      indexes :audio_channels,     multiple: true
      indexes :audio_languages,    multiple: true
      indexes :subtitle_languages, multiple: true
      indexes :video_codec
      indexes :resolution
      indexes :checksum
      indexes :filesize, type: 'integer'
      indexes :height,   type: 'integer'
      indexes :width,    type: 'integer'
    end
  end

  def as_indexed_json(options={})
    as_json \
      only: [
        :id,
        :server_id,
        :filesize,
        :checksum,
      ],
      methods: [
        :folder,
        :filename,
        :duration,
        :audio_codecs,
        :audio_channels,
        :audio_languages,
        :subtitle_languages,
        :video_codec,
        :resolution,
        :filesize,
        :height,
        :width,
      ]
  end
  
  def filename
    path.split("/").last
  end
  
  def folder
    path.sub(%r(/[^/]+$),"")
  end
  
end
