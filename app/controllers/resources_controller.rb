class ResourcesController < ApplicationController
  
  PAGELEN_DEFAULT = 20
  PAGELEN_MAX     = 500
  
  inherit_resources
  
  protected
  
  def collection
    @filters  = SearchFilters.new(params[:query].to_s)
    remaining = @filters.remaining
    
    server_id       = @filters[:server_id]
    duration        = @filters[:duration]
    duration_min    = @filters[:duration_min]
    duration_max    = @filters[:duration_max]
    
    facets = {
      :resolution         => @filters[:resolution],
      :filesize           => @filters[:filesize],
      :video_codec        => @filters[:video_codec],
      :audio_channels     => @filters[:audio_channels],
      :audio_languages    => @filters[:audio_language],
      :subtitle_languages => @filters[:subtitle_language],
    }
    
    
    
    @resources ||= resource_class.search :include => [:server] do
      
      paginate(:page => params[:page], :per_page => per_page)
      
      keywords remaining do
        highlight :path_without_filename, :filename
      end
      
      with(:server_id, server_id) unless server_id.blank?
      
      with(:duration).between(duration) unless duration.blank?
      with(:duration).greater_than(duration_min) unless duration_min.blank?
      with(:duration).less_than(duration_max)    unless duration_max.blank?
      
      for field, value in facets
        filter = with(field, value) unless value.blank?
        facet field, :exclude => filter
      end
      
      facet :filesize do
        row "0..10m" do
          with :filesize, 0..(10.megabytes)
        end
        row "10m..100m" do
          with :filesize, (10.megabytes)..(100.megabytes)
        end
        row "100m..1g" do
          with :filesize, (100.megabytes)...(1.gigabyte)
        end
        row "1g..10g" do
          with :filesize, (1.gigabyte)..(10.gigabytes)
        end
        row "10g..100g" do
          with :filesize, (10.gigabytes)..(100.gigabytes)
        end
      end
      
      facet :duration do
        row 0..20 do
          with :duration, 0..20
        end
        row 21..60 do
          with :duration, 21..60
        end
        row 61..120 do
          with :duration, 61..120
        end
        row 121..999 do
          with :duration, 121..999
        end
      end
    end
    
  end
  
  def per_page
    per_page = params[:per_page].to_i
    per_page = PAGELEN_DEFAULT if per_page < 1
    [per_page, PAGELEN_MAX].min
  end
  
  
end
