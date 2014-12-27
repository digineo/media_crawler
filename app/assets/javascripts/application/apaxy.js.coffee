$(document).on 'ready page:load', ->
  $("a.file").each ->
    $(@).addClass "file-" + $(@).text().split(".").pop()
