
updateTable = ->
  files = $("#files")
  return unless files.length

  # Find and Clear tbody
  tbody = files.find("tbody")
  nav   = $("#path")

  # Get Hash
  hash  = window.location.hash
  if hash != ""
    parts = hash.substring(1).split("/")
    path  = hash.substring(1) + "/"
  else
    path  = ""
    parts = []

  # Build Navigation
  nav.html("")
  for part, i in parts
    if i == parts.length-1
      nav.append part
    else
      nav.append $("<a></a>", href: "#" + parts[0..i].join("/")).text(part)
    nav.append "/"

  # Build Table
  server_id = files.data('server-id')
  $.getJSON "/data/servers/#{server_id}/#{path}content.json", (data)->
    total = $.map(data.children, (c)-> c.size).sum() + $.map(data.files, (c)-> c.size).sum()

    sizeCell = (size)->
      width = Math.round(Math.log(size) * 5)
      r     = (40 + Math.round(Math.log(size) * 10)) % 255
      $("<td></td>").append("<div class='bar' style='width:#{width}px;background:hsla(#{r},100%,70%,0.5)'><span>#{filesize size*1024}</span></div>")

    tbody.html("")

    # Directory
    for child in data.children
      tr = $ "<tr></tr>"
      sizeCell(child.size).appendTo tr
      $("<td></td>").append($("<a></a>", href: "##{path}#{child.name}").text(child.name)).appendTo tr
      $("<td></td>").text(child.count).appendTo tr
      tr.appendTo tbody

    # File
    for child in data.files
      tr = $ "<tr></tr>"
      sizeCell(child.size).appendTo tr
      $("<td></td>").text(child.name).appendTo tr
      $("<td></td>").appendTo tr
      tr.appendTo tbody

$(document).on 'ready page:load', updateTable
$(window).on   'hashchange',      updateTable
