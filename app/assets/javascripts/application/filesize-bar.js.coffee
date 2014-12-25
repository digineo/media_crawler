
window.filesizeBar = (size) ->
  width = Math.round(Math.log(size) * 4)
  r     = (40 + Math.round(Math.log(size) * 10)) % 255
  "<div class='filesize'><div class='bar' style='width:#{width}%;background:hsla(#{r},100%,70%,0.5)'><span>#{filesize size*1024}</span></div></div>"
  

jQuery.fn.showFilesize = ->
  @each ()->
    e = $(this)
    e.html filesizeBar(parseInt(e.text()))


$(document).on 'ready page:load', ->
  $(".filesize").showFilesize()
  return
