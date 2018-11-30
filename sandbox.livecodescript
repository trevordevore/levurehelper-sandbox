script "Sandbox Library"
local sFilesA


function sandboxIsInUse
  return _macosSandboxIsInUse()
end sandboxIsInUse


/**
Summary: Returns an array containing the bookmark data for all files that have been registered with the library.

Parameters:
pFilterOutNonPersistent: Pass in true to filter out non persistent bookmarks.

Description:
When you call `sandboxStoreBookmarkDataForFile` the bookmark data is stored internally within
the library. Use this handler to get an array that is indexed by filename. Each filename
key has an array for a value. The array contains a "bookmark data" key which contains the
bookmark data for the file.

Your application may benefit by storing and restoring file bookmarks all together.
You can store the array returned by this function in your application preferences so that
it can be restored the next time the application launches using `sandboxSetBookmarkDataForFiles`.

Whether or not this makes sense depends on your use case. For applications that have a
recent files menu it makes more sense to store the file bookmark data with each recent files entry.
If your application prompts the user for access to a couple of different files and you don't want
a separate preference for each file/folder bookmark then storing and restoring them all together
can make sense.

The `persistent` flag that is attached to bookmarks allows you to mix both approaches. If you
want to store some bookmarks seprately (e.g. recent files) and handle the rest all together then
you would mark the bookmarks for recent files as non-persistent when calling `sandboxSetBookmarkDataForFile`
or `sandboxStoreBookmarkDataForFile` and pass in `true` for `pFilterOutNonPersistent` when
calling this function.

Returns: Array
*/
function sandboxGetBookmarkDataForFiles pFilterOutNonPersistent
  local tFilesA

  repeat for each key tFile in sFilesA
    if pFilterOutNonPersistent and not sFilesA[tFile]["persistent"] then next repeat

    put sFilesA[tFile]["bookmark data"] into tFilesA[tFile]["bookmark data"]
    put sFilesA[tFile]["persistent"] into tFilesA[tFile]["persistent"]
  end repeat

  return tFilesA
end sandboxGetBookmarkDataForFiles


/**
Summary: Sets the array of bookmark data for filenames.

Parameters:
pFilesA: An array whose keys are full filenames. Each filename key has an array for a value. Each array has a "bookmark data" key.

Description:
When launching your application you can use this handler to restore the internal
array of bookmark data that was stored using `sandboxGetBookmarkDataForFiles()`.

Returns: nothing
*/
command sandboxSetBookmarkDataForFiles pFilesA
  if not _macosSandboxIsInUse() then return empty

  local tFile

  put empty into sFilesA

  repeat for each key tFile in pFilesA
    if pFilesA[tFile]["bookmark data"] is not empty then
      put pFilesA[tFile]["bookmark data"] into sFilesA[tFile]["bookmark data"]
      put pFilesA[tFile]["persistent"] into sFilesA[tFile]["persistent"]
    end if
  end repeat

  return empty
end sandboxSetBookmarkDataForFiles


/**
Summary: Returns the bookmark data for a filename that has been stored internally.

Parameters:
pFilename: The full path to a file.

Description:
Bookmark data is stored for a file when calling `sandboxStoreBookmarkDataForFile` or
when setting the bookmark data using `sandboxSetBookmarkDataForFile` or
`sandboxSetBookmarkDataForFiles`.

Returns: Bookmark data (binary)
*/
function sandboxGetBookmarkDataForFile pFilename
  return sFilesA[pFilename]["bookmark data"]
end sandboxGetBookmarkDataForFile


/**
Summary: Stores bookmark data for a file.

Parameters:
pFilename: The full path to the file.
pBookmarkData: The bookmark data to assign to the file.
pIsPersistent: Pass in `false` to mark this bookmark as non persistent.

Description:
Call this handler if you have bookmark data for a file that you need
to set for the session. See docs for `sandboxGetBookmarkDataForFiles()` for
an explanation of pIsPersistent.

Returns: nothing
*/
command sandboxSetBookmarkDataForFile pFilename, pBookmarkData, pIsPersistent
  if _macosSandboxIsInUse() then
    put pBookmarkData into sFilesA[pFilename]["bookmark data"]
    put pIsPersistent is not false into sFilesA[pFilename]["persistent"]

    # Clean up memory if there is no relevant data left to track
    if pBookmarkData is empty and sFilesA[pFilename]["security scoped filename"] is empty then
      delete local sFilesA[pFilename]
    end if
  end if

  return empty
end sandboxSetBookmarkDataForFile


/**
Summary: Stores bookmark data for a file opened using a system file/folder dialog or drag and drop.

Parameters:
pFilename: The full path to the file.
pReadOnly: Pass in true if your application only needs read access to the file.
pIsPersistent: Pass in `false` to mark this bookmark as non persistent.

Description:
When a user selects a file through a system dialog or drags in onto your application
the OS gives your app permission to open that file. If your application needs to open
that file again without prompting the user then you need to store bookmark data for
the file so that you can generate a security-scoped url later on.

See docs for `sandboxGetBookmarkDataForFiles()` for an explanation of pIsPersistent.

Returns: Error
*/
command sandboxStoreBookmarkDataForFile pFilename, pReadOnly, pIsPersistent
  local tError, tBookmarkData

  if _macosSandboxIsInUse() then
    put macsandGetFileBookmarkData(pFilename, pReadOnly is true, tError) into tBookmarkData

    if tError is empty then
      put tBookmarkData into sFilesA[pFilename]["bookmark data"]
      put pIsPersistent is not false into sFilesA[pFilename]["persistent"]
    end if
  end if

  return tError for error
end sandboxStoreBookmarkDataForFile


/**
Summary: Restores access to a file for your application using stored bookmark data.

Parameters:
pFilename: The full path to the file.

Description:
If you have previously stored bookmark data for a file (e.g. in a previous application session)
then you can restore access to that file in another session by calling this handler.

Returns: Error
*/
command sandboxRestoreAccessToFile pFilename
  local tError

  if _macosSandboxIsInUse() then
    local tSecurityScopedFilename, tBookmarkDataIsStale

    if sFilesA[pFilename]["bookmark data"] is not empty then
      put macsandStartAccessingFile(sFilesA[pFilename]["bookmark data"], tBookmarkDataIsStale, tError) into tSecurityScopedFilename

      # If pFilename exists but bookmark data is stale then try to refresh the bookmark
      if tBookmarkDataIsStale and there is a file pFilename then
        local tBookmarkData
        put macsandGetFileBookmarkData(pFilename, false, tError) into tBookmarkData
        if tError is empty then
          put macsandStartAccessingFile(tBookmarkData, tBookmarkDataIsStale, tError) into tSecurityScopedFilename
          if not tBookmarkDataIsStale and tError is empty then
            put tBookmarkData into sFilesA[pFilename]["bookmark data"]
          end if
        end if
      end if

      if tError is empty then
        put tSecurityScopedFilename into sFilesA[pFilename]["security scoped filename"]
      end if
    end if
  end if

  return tError for error
end sandboxRestoreAccessToFile


/**
Summary: Tells the operating system that you no longer need access to a file.

Description:
If you called `sandboxRestoreAccessToFile()` for a particular file then when you
are done using it you need to tell the operating system that you no longer need
access to the file.

Returns: nothing
*/
command sandboxStopAccessingFile pFilename
  if _macosSandboxIsInUse() then
    get macsandStopAccessingFile(pFilename)
    delete local sFilesA[pFilename]["security scoped filename"]
  end if

  return empty
end sandboxStopAccessingFile


/**
Summary: Stops accessing all files that have been initialized using `sandboxRestoreAccessToFile`.

Returns: nothing
*/
command sandboxStopAccessingAllFiles
  local tFile

  repeat for each key tFile in sFilesA
    sandboxStopAccessingFile tFile
  end repeat

  return empty
end sandboxStopAccessingAllFiles


private function _macosSandboxIsInUse
  if _isMacAppStoreProfile() then
    set the itemDelimiter to "."

    return the platform is "macos" AND item 1 of the systemVersion > 10 \
          OR (item 1 of the systemVersion is 10 AND item 2 of the systemVersion > 7) \
          OR (item 1 of the systemVersion is 10 AND item 2 of the systemVersion is 7 AND item 3 of the systemVersion >= 3)
  else
    return false
  end if
end _macosSandboxIsInUse


private function _isMacAppStoreProfile
  return levureBuildProfile() begins with "mac app store"
end _isMacAppStoreProfile
