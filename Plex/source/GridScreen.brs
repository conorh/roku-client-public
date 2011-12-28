'*
'* Initial attempt at a grid screen.
'*
Function preShowGridScreen() As Object
  m.port = CreateObject("roMessagePort")
  grid = CreateObject("roGridScreen")
  grid.SetMessagePort(m.port)

  grid.SetDisplayMode("photo-fit")

  return grid
End Function

Function showGridScreen(grid, content) As Integer
  if validateParam(grid, "roGridScreen", "showGridScreen") = false return -1
  if validateParam(content, "roAssociativeArray", "showGridScreen") = false return -1

  print "Show grid screen for key ";content.key

  retrieving = CreateObject("roOneLineDialog")
  retrieving.SetTitle("Retrieving ...")
  retrieving.ShowBusyAnimation()
  retrieving.Show()

  server = content.server
  contentKey = content.key
  currentTitle = content.Title

  queryResponse = server.GetQueryResponse(content.sourceUrl, contentKey)

  oldNames= server.GetListNames(queryResponse)
  oldKeys = server.GetListKeys(queryResponse)

  keys = CreateObject("roArray", 10, true)
  for each key in oldKeys
    if key = "all"
      keys.push(key)
    end if
  next

  contentArray = []
  rowCount = 0

  for each key in keys
    print "doing key";key
    response = server.GetQueryResponse(queryResponse.sourceUrl, key)
    contentList = server.GetContent(response)

    'Split the list into 5 entries per row
    rowCount = int(contentList.count() / 5)
    if contentList.count() MOD 5 > 0 then
      rowCount = rowCount + 1
    end if

    print "total rows";rowCount

    for i = 0 to rowCount-1
      length = 5
      if contentList.count() < 5 then
        length = contentList.count()
      end if
      contentArray[i] = CreateObject("roArray", length, false)
      for j = 0 to length-1
        contentArray[i].Push(contentList.Shift())
      next
    next
  next

  grid.SetupLists(rowCount)
  names = CreateObject("roArray", rowCount, false)
  for i = 0 to rowCount-1
    names.Push("row" + i.tostr())
  next
  grid.SetListNames(names)

  for i = 0 to rowCount-1
    grid.setContentList(i, contentArray[i])
  next

  grid.show()
  retrieving.close()

  while true
    msg = wait(0, m.port)

    if type(msg) = "roGridScreenEvent" then
      if msg.isListItemSelected() then
        row = msg.GetIndex()
        if row < rowCount then
          selection = msg.getData()

          contentSelected = contentArray[row][selection]
          contentType = contentSelected.ContentType

          print "Content type in grid screen:"+contentType

          if contentType = "movie" OR contentType = "episode" then
            displaySpringboardScreen(contentSelected.title, contentArray[row], selection)
          else if contentType = "clip" then
            playPluginVideo(server, contentSelected)
          else if contentSelected.viewGroup <> invalid AND contentSelected.viewGroup = "Store:Info" then
            ChannelInfo(contentSelected)
          else
            showNextPosterScreen(contentSelected.title, contentSelected)
          end if
        end if
      else if msg.isScreenClosed() then
        return -1
      end if
    end if
  end while

  return 0
End Function

Function showNextGridScreen(currentTitle, selected As Object) As Dynamic
    if validateParam(selected, "roAssociativeArray", "showNextGridScreen") = false return -1
    grid = preShowGridScreen()
    showGridScreen(grid, selected)
    return 0
End Function