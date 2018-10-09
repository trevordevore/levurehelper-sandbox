- [sandboxGetBookmarkDataForFile](#sandboxGetBookmarkDataForFile)
- [sandboxGetBookmarkDataForFiles](#sandboxGetBookmarkDataForFiles)
- [sandboxRestoreAccessToFile](#sandboxRestoreAccessToFile)
- [sandboxSetBookmarkDataForFile](#sandboxSetBookmarkDataForFile)
- [sandboxSetBookmarkDataForFiles](#sandboxSetBookmarkDataForFiles)
>
- [sandboxStopAccessingAllFiles](#sandboxStopAccessingAllFiles)
- [sandboxStopAccessingFile](#sandboxStopAccessingFile)
- [sandboxStoreBookmarkDataForFile](#sandboxStoreBookmarkDataForFile)

<br>

## <a name="sandboxGetBookmarkDataForFile"></a>sandboxGetBookmarkDataForFile

**Type**: function

**Syntax**: `sandboxGetBookmarkDataForFile(<pFilename>)`

**Summary**: Returns the bookmark data for a filename that has been stored internally.

**Returns**: Bookmark data (binary)

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilename` |  The full path to a file. |

**Description**:

Bookmark data is stored for a file when calling `sandboxStoreBookmarkDataForFile` or
when setting the bookmark data using `sandboxSetBookmarkDataForFile` or
`sandboxSetBookmarkDataForFiles`.

<br>

## <a name="sandboxGetBookmarkDataForFiles"></a>sandboxGetBookmarkDataForFiles

**Type**: function

**Syntax**: `sandboxGetBookmarkDataForFiles(<pFilterOutNonPersistent>)`

**Summary**: Returns an array containing the bookmark data for all files that have been registered with the library.

**Returns**: Array

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilterOutNonPersistent` |  Pass in true to filter out non persistent bookmarks. |

**Description**:

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

<br>

## <a name="sandboxRestoreAccessToFile"></a>sandboxRestoreAccessToFile

**Type**: command

**Syntax**: `sandboxRestoreAccessToFile <pFilename>`

**Summary**: Restores access to a file for your application using stored bookmark data.

**Returns**: Error

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilename` |  The full path to the file. |

**Description**:

If you have previously stored bookmark data for a file (e.g. in a previous application session)
then you can restore access to that file in another session by calling this handler.

<br>

## <a name="sandboxSetBookmarkDataForFile"></a>sandboxSetBookmarkDataForFile

**Type**: command

**Syntax**: `sandboxSetBookmarkDataForFile <pFilename>,<pBookmarkData>,<pIsPersistent>`

**Summary**: Stores bookmark data for a file.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilename` |  The full path to the file. |
| `pBookmarkData` |  The bookmark data to assign to the file. |
| `pIsPersistent` |  Pass in `false` to mark this bookmark as non persistent. |

**Description**:

Call this handler if you have bookmark data for a file that you need
to set for the session. See docs for `sandboxGetBookmarkDataForFiles()` for
an explanation of pIsPersistent.

<br>

## <a name="sandboxSetBookmarkDataForFiles"></a>sandboxSetBookmarkDataForFiles

**Type**: command

**Syntax**: `sandboxSetBookmarkDataForFiles <pFilesA>`

**Summary**: Sets the array of bookmark data for filenames.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilesA` |  An array whose keys are full filenames. Each filename key has an array for a value. Each array has a "bookmark data" key. |

**Description**:

When launching your application you can use this handler to restore the internal
array of bookmark data that was stored using `sandboxGetBookmarkDataForFiles()`.

<br>

## <a name="sandboxStopAccessingAllFiles"></a>sandboxStopAccessingAllFiles

**Type**: command

**Syntax**: `sandboxStopAccessingAllFiles `

**Summary**: Stops accessing all files that have been initialized using `sandboxRestoreAccessToFile`.

**Returns**: nothing

<br>

## <a name="sandboxStopAccessingFile"></a>sandboxStopAccessingFile

**Type**: command

**Syntax**: `sandboxStopAccessingFile <pFilename>`

**Summary**: Tells the operating system that you no longer need access to a file.

**Returns**: nothing

**Description**:

If you called `sandboxRestoreAccessToFile()` for a particular file then when you
are done using it you need to tell the operating system that you no longer need
access to the file.

<br>

## <a name="sandboxStoreBookmarkDataForFile"></a>sandboxStoreBookmarkDataForFile

**Type**: command

**Syntax**: `sandboxStoreBookmarkDataForFile <pFilename>,<pReadOnly>,<pIsPersistent>`

**Summary**: Stores bookmark data for a file opened using a system file/folder dialog or drag and drop.

**Returns**: Error

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pFilename` |  The full path to the file. |
| `pReadOnly` |  Pass in true if your application only needs read access to the file. |
| `pIsPersistent` |  Pass in `false` to mark this bookmark as non persistent. |

**Description**:

When a user selects a file through a system dialog or drags in onto your application
the OS gives your app permission to open that file. If your application needs to open
that file again without prompting the user then you need to store bookmark data for
the file so that you can generate a security-scoped url later on.

See docs for `sandboxGetBookmarkDataForFiles()` for an explanation of pIsPersistent.

