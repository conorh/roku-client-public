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
	
	names = server.GetListNames(queryResponse)
	keys = server.GetListKeys(queryResponse)
	
    grid.SetupLists(names.Count()) 
	grid.SetListNames(names)
        
    contentArray = []
    rowCount = 0
	altCount = 0
	
	gridShown = false
	
    for each key in keys
		print "Page key:"+key

		response = server.GetQueryResponse(queryResponse.sourceUrl, key)
		'response = server.GetPaginatedQueryResponse(queryResponse.sourceUrl, key, 0, 50)
		'printXML(response.xml, 1)
		
		contentList = server.GetContent(response)
		
		grid.setContentList(rowCount, contentList)
					
		contentArray[rowCount] = []
		
		itemCount = 0
		for each item in contentList
			contentArray[rowCount][itemCount] = item
			itemCount = itemCount + 1
		next
		
		' make sure any section without content is not shown
		if itemCount = 0 then
			grid.setListVisible(rowCount, false)
		end if
		
		rowCount = rowCount + 1
		
		' after the second row let's show the grid as a test...
		if rowCount = 2 then
			grid.show()
			retrieving.close()
			gridShown = true
		end if
    next
	
	' now if there were less than 2 rows then let's just show the grid...
	if gridShown = false then
		grid.show()
		retrieving.close()
	end if
	
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
				end If
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
	return 0
End Function

Function showNextGridScreen(currentTitle, selected As Object) As Dynamic
    if validateParam(selected, "roAssociativeArray", "showNextGridScreen") = false return -1
    grid = preShowGridScreen()
    showGridScreen(grid, selected)
    return 0
End Function