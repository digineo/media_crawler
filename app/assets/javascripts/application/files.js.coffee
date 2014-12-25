
updateTable = ->
  files = $("#files")
  return unless files.length

  # Find important stuff
  server_id = files.data('server-id')
  entries   = files.find(".entries")
  $path     = $("#path")
  $modified = $("#modified")

  # Get Hash
  hash  = window.location.hash
  if hash != ""
    parts = hash.substring(1).split("/")
    path  = hash.substring(1) + "/"
  else
    path  = ""
    parts = []

  # Build Navigation
  $path.html("")
  for part, i in parts
    if i == parts.length-1
      $path.append part
    else
      $path.append $("<a></a>", href: "#" + parts[0..i].join("/")).text(part)
    $path.append "/"

  # Set window title
  document.title = $("h1").text()

  # Load directory content
  $.getJSON "/data/servers/#{server_id}/#{path}content.json", (data, status, xhr)->
    modified = xhr.getResponseHeader("Last-Modified")
    total   = $.map(data.children, (c)-> c.size).sum() + $.map(data.files, (c)-> c.size).sum()

    $modified.text modified

    # Clear entries
    entries.html("")

    # Parent directory
    if parts.length
      entries.append("<li><a href='#" + parts[0..-2].join("/") + "' class='folder folder-parent' >Parent Directory</a></li>")

    # Directories
    for child in data.children
      tr = $ "<li></li>"
      $(filesizeBar(child.size)).appendTo tr
      $("<a></a>", href: "##{path}#{child.name}", class: 'folder').text(child.name).appendTo tr
      tr.append(" <span class='badge'>#{child.count}</span>")
      tr.appendTo entries

    # Files
    for child in data.files
      tr = $ "<li></li>"
      $(filesizeBar(child.size)).appendTo tr
      $("<span></span>", class: "file file-#{child.name.split('.').pop()}").text(child.name).appendTo tr
      tr.appendTo entries

$(document).on 'ready page:load', updateTable
$(window).on   'hashchange',      updateTable
