
updateTable = ->
  files = $("#files")
  return unless files.length

  # Find and Clear tbody
  server_id = files.data('server-id')
  tbody     = files.find("tbody")
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

    sizeCell = (size)->
      width = Math.round(Math.log(size) * 5)
      r     = (40 + Math.round(Math.log(size) * 10)) % 255
      $("<td></td>").append("<div class='bar' style='width:#{width}px;background:hsla(#{r},100%,70%,0.5)'><span>#{filesize size*1024}</span></div>")

    # Clear table
    tbody.html("")

    # Parent directory
    if parts.length
      tbody.append("<tr><td></td><td><a href='#' class='folder folder-parent' >Parent Directory</a></td></tr>")

    # Directories
    for child in data.children
      tr = $ "<tr></tr>"
      sizeCell(child.size).appendTo tr
      $("<td></td>").append($("<a></a>", href: "##{path}#{child.name}", class: 'folder').text(child.name)).appendTo tr
      $("<td></td>").text(child.count).appendTo tr
      tr.appendTo tbody

    # Files
    for child in data.files
      tr = $ "<tr></tr>"
      sizeCell(child.size).appendTo tr
      $("<td></td>").append($("<span></span>", class: "file file-#{child.name.split('.').pop()}").text(child.name)).appendTo tr
      $("<td></td>").appendTo tr
      tr.appendTo tbody

$(document).on 'ready page:load', updateTable
$(window).on   'hashchange',      updateTable
