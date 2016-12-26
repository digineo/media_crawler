
updateTable = ->
  files = $("#files")
  return unless files.length

  # Find important stuff
  server_id = files.data('server-id')
  entries   = files.find(".entries")
  $path     = $("#path")
  $modified = $("#modified")
  $link     = $("#link")


  # Get Hash
  hash  = window.location.hash
  if hash != ""
    parts = hash.substring(1).split("/")
    path  = hash.substring(1) + "/"
  else
    path  = ""
    parts = []

  $path.html("")

  # Build Navigation
  for part, i in parts
    if i == parts.length-1
      $path.append decodeURI(part)
    else
      $path.append $("<a></a>", href: "#" + parts[0..i].join("/")).text(decodeURI(part))
    $path.append "/"

  # Set window title
  document.title = "cyber of " + $("h1").text()

  # Load directory content
  $.getJSON "/data/#{server_id}/entries/#{path}index.json", (data, status, xhr)->
    modified = xhr.getResponseHeader("Last-Modified")
    total   = $.map(data, (c)-> c.size).sum()

    $modified.text modified

    uri = $link.data("baseUri") + path
    $link.attr("href", uri).text(uri)

    # Clear entries
    entries.html("")

    # Parent directory
    if parts.length
      entries.append("<li><a href='#" + parts[0..-2].join("/") + "' class='folder folder-parent' >Parent Directory</a></li>")

    for child in data
      tr = $ "<li></li>"
      $(filesizeBar(child.size)).appendTo tr
      if child.type=="dir"
        # Directory
        $("<a></a>", href: "##{path}#{child.name}", class: 'folder').text(child.name).appendTo tr
        tr.append(" <span class='badge'>#{child.count}</span>") if child.count
      else
        # File
        $("<span></span>", class: "file file-#{child.name.split('.').pop()}").text(child.name).appendTo tr
      tr.appendTo entries

$(document).on 'ready page:load', updateTable
$(window).on   'hashchange',      updateTable
