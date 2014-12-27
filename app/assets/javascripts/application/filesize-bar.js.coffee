
window.filesizeBar = (size) ->
  width = Math.round(Math.log(size) * 4)
  hue   = (60 + Math.round(Math.log(size) * 30 / Math.LN10 )) % 360
  "<div class='filesize'><div class='bar' style='width:#{width}%;background:hsla(#{hue},100%,75%,0.5)'><span>#{filesize size*1024}</span></div></div>"
  

jQuery.fn.showFilesize = ->
  @each ()->
    e = $(this)
    e.html filesizeBar(parseInt(e.text()))


$(document).on 'ready page:load', ->
  $(".filesize").showFilesize()
  return
