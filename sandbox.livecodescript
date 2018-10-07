script "Sandbox Library"
local sFilesA


function sandboxIsInUse
  return _macosSandboxIsInUse()
end sandboxIsInUse


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


/**
Summary: Returns an array containing the bookmark data for all files that have been registered with the library.

Description:
When you call `sandboxStoreBookmarkDataForFile` the bookmark data is stored internally within
the library. Use this handler to get an array that is indexed by filename. Each filename
key has an array for a value. The array contains a "bookmark data" key which contains the
bookmark data for the file.

You can store the array returned by this function in your application preferences so that
it can be restored the next time the application launches using `sandboxSetBookmarkDataForFiles`.

Returns: Array
*/
function sandboxGetBookmarkDataForFiles
  local tFilesA

  repeat for each key tFile in sFilesA
    put sFilesA[tFile]["bookmark data"] into tFilesA[tFile]["bookmark data"]
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

Description:
Call this handler if you have bookmark data for a file that you need
to set for the session.

Returns: nothing
*/
command sandboxSetBookmarkDataForFile pFilename, pBookmarkData
  if _macosSandboxIsInUse() then
    put pBookmarkData into sFilesA[pFilename]["bookmark data"]
  end if

  return empty
end sandboxSetBookmarkDataForFile


/**
Summary: Stores bookmark data for a file opened using a system file/folder dialog or drag and drop.

Parameters:
pFilename: The full path to the file.

Description:
When a user selects a file through a system dialog or drags in onto your application
the OS gives your app permission to open that file. If your application needs to open
that file again without prompting the user then you need to store bookmark data for
the file so that you can generate a security-scoped url later on.

Returns: Error
*/
command sandboxStoreBookmarkDataForFile pFilename
  local tError, tBookmarkData

  if _macosSandboxIsInUse() then
    if sFilesA[pFilename]["bookmark data"] is empty then
      put macsandGetFileBookmarkData( pFilename ) into tBookmarkData
      if tBookmarkData begins with "error:" then
        put "unable to get file bookmark data:" && word 2 to -1 of tBookmarkData into tError
      end if

      if tError is empty then
        put tBookmarkData into sFilesA[pFilename]["bookmark data"]
      end if
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
  if _macosSandboxIsInUse() then
    local tError, tSecurityScopedFilename

    if sFilesA[pFilename]["bookmark data"] is not empty then
      put macsandStartAccessingFile(sFilesA[pFilename]["bookmark data"]) into tSecurityScopedFilename
      if tSecurityScopedFilename begins with "error:" then
        put "unable to open file " & quote & pFilename & quote & ":" && word 2 to -1 of tSecurityScopedFilename into tError
      else
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
