#
# Search scoped to a host and a path
#
$(document).on 'ready page:load', ->
  $("#subsearch").submit (e)->
    e.preventDefault()
    $this = $ @
    query = $this.find("input[type=text]").val()
    path  = '/' + $("#path").text().replace(/\/$/,"")

    parts = []
    parts.push 'host:' + $("#host").text()
    parts.push 'path:' + ( if path.indexOf(" ") == -1 then path else "\"#{path}\"")
    parts.push query

    Turbolinks.visit $this.attr('action') + "?query=" + encodeURIComponent(parts.join(" "))
    
    return
