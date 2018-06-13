--[[
        OpenInWhatever.lua
--]]


local OpenInWhatever, dbg, dbgf = Object:newClass{ className = "OpenInWhatever", register = true }



--- Constructor for extending class.
--
function OpenInWhatever:newClass( t )
    return Object.newClass( self, t )
end


--- Constructor for new instance.
--
function OpenInWhatever:new( t )
    local o = Object.new( self, t )
    return o
end



--  Private method...
--  returns status, error-message.
function OpenInWhatever:_privateMethod( call )
    -- app:callingAssert( call ~= nil, "no call" )
    return true, nil
end



function OpenInWhatever:whatever( index, allSel )
    -- variables accessible in finale method (could also be assigned to call object).
    local selPhotosEtc -- selected photos and other things for restoral.
    app:call( Service:new{ name="Open In Whatever", async=true, progress=true, main=function( call )
        call:initStats{ 'totalSelected', 'updated', 'okAlready', 'videoSkipped', 'missingSkipped', 'virtualCopySkipped', 'notWritableSkipped', 'dngSkipped' }
        local selPhotos = cat:getSelectedPhotos() -- ditto
        -- local selPhotos = cat:getSelectedPhotos() -- restoral of original photos etc. upon completion is not required.
        if #selPhotos == 0 then
            app:show{ warning="Select photo(s) first." }
            call:cancel()
            return
        end
        call:setStat( 'totalSelected', #selPhotos )
        call:setCaption( "Acquiring metadata..." )
        local cache = lrMeta:createCache{ photos=selPhotos, rawIds={ 'path', 'isVirtualCopy', 'fileFormat' }, fmtIds={ 'copyName', 'fileName' } }
        call:setCaption( "Scrutinizing selected photos..." )
        local photos = {} -- for saving metadata and then processing.
        local readPhotos = {} -- updated: read metadata.
        local yc = 0
        for i, photo in ipairs( selPhotos ) do
            call:setPortionComplete( i-1, #selPhotos )
            yc = app:yield( yc )
            repeat
                local fmt = cache:getRawMetadata( photo, 'fileFormat' )
                --[[ consider video skip option? ###1
                if fmt == 'VIDEOOOOO' then
                    call:incrStat( 'videoSkipped' )
                    break
                end
                --]]
                local virt = cache:getRawMetadata( photo, 'isVirtualCopy' )
                if virt then
                    call:incrStat( 'virtualCopySkipped' )
                    break
                end
                local path = cache:getRawMetadata( photo, 'path' )
                if not fso:existsAsFile( path ) then
                    call:incrStat( 'missingSkipped' )
                    break
                end
                photos[#photos + 1] = photo
            until true
            if call:isQuit() then
                return
            end
        end
        call:setPortionComplete( 1 )
        if #photos == 0 then
            app:show{ info="No photos ripe for opening." }
            call:cancel()
            return
        end
        local s, m = true
        -- Note: metadata must be saved, since that's where exif info comes from (rgb anyway - not proprietary raw, and hopefully not raw dng either(?)), even in test mode.
        if #photos == 1 then
            -- Catalo g : s avePhotoMetadata( photo, photoPath, targ, call, noVal )
            -- s, m = cat:savePhotoMetadata( photos[1], cache:getRawMetadata( photos[1], 'path' ), nil, call )
        else
            -- Catalo g : s aveMetadata( photos, preSelect, restoreSelect, alreadyInGridMode, service )
            -- s, m = cat:saveMetadata( photos, true, false, false, call )
            -- s = true -- ###
        end
        local function openMostSelected()
            local appPath = app:getPref( 'appPath_'..index )
            local params = app:getPref( 'cmdLineParams_'..index )
            local photo = catalog:getTargetPhoto()
            local photoPath = cache:getRawMetadata( photo, 'path' )
            if fso:existsAsFile( photoPath ) then
                app:log( photoPath )
                if str:is( params ) then
                    app:log( "Opening most selected file in ^1 via command line to support cmd-line parameters: ^2.", appPath, params )
                    LrShell.openPathsViaCommandLine( { photoPath }, appPath, params )
                else
                    app:log( "Opening most selected file in ^1 (there are no cmd-line parameters).", appPath )
                    LrShell.openFilesInApp( { photoPath }, appPath )
                end
                call:incrStat( 'updated' )
            else
                app:logWarning( "^1 is missing or offline.", photoPath )
            end
        end
        local function openAllSelected()
            local appPath = app:getPref( 'appPath_'..index )
            local params = app:getPref( 'cmdLineParams_'..index )
            local files = {}
            for i, photo in ipairs( photos ) do
                local photoPath = cache:getRawMetadata( photo, 'path' )
                app:log( photoPath )
                if fso:existsAsFile( photoPath ) then
                    files[#files + 1] = photoPath
                    call:incrStat( 'updated' )
                end
            end
            if #files > 0 then
                if str:is( params ) then
                    app:log( "Opening ^1 in ^2 via command line to support cmd-line parameters: ^3.", str:nItems( #files, "files" ), appPath, params )
                    LrShell.openPathsViaCommandLine( files, appPath, params )
                else
                    app:log( "Opening ^1 in ^2 (there are no cmd-line parameters).", str:nItems( #files, "files" ), appPath )
                    LrShell.openFilesInApp( files, appPath )
                end
            else
                app:logWarning( "There were no files (existing on disk) to open." )
            end
        end
        if s then
            call:setCaption( "Doing something to photos and/or their metadata..." )
            if gbl:getValue( 'exifTool' ) then
                local s, m = exifTool:isUsable()
                if not s then
                    app:logErr( m )
                    return
                end
                call.ets = exifTool:openSession( title )
            -- else - no et
            end
            app:log()
            if allSel then
                openAllSelected()
            else
                openMostSelected()
            end
            app:log()
        else
            app:logErr( m )
        end
    end, finale=function( call )
        if gbl:getValue( 'exifTool' ) then
            exifTool:closeSession( call.ets ) -- handles nil appropriately.
        end
        if call.status then
            if not call:isQuit() then
                app:log()
                app:log( "^1 total selected", call:getStat( 'totalSelected' ) )
                app:log( "^1 opened", call:getStat( 'updated' ) )
                app:logStat( "^1 not writable - skipped", call:getStat( 'notWritableSkipped' ), "photos" )
                app:logStat( "^1 skipped", call:getStat( 'dngSkipped' ), "DNGs" )
                app:logStat( "^1 skipped", call:getStat( 'videoSkipped' ), "videos" )
                app:logStat( "^1 skipped", call:getStat( 'missingSkipped' ), "missing files" )
                app:logStat( "^1 skipped", call:getStat( 'virtualCopySkipped' ), "virtual copies" )
            else
                app:logv( "quit prematurely, something should have already been logged about it..." )
            end
        else
            app:logv( "error caught, should have been logged - ^1", call.message )
        end
    end } )
end



-- plugin manager button handler.
function OpenInWhatever:commit( id, title )
    app:call( Service:new{ name=title, async=true, guard=App.guardVocal, progress=true, main=function( call )
        local infoVirginalFile = LrPathUtils.child( _PLUGIN.path, "InfoVirginal.lua" )
        if not fso:existsAsFile( infoVirginalFile ) then
            app:error( "file missing: ^1", infoVirginalFile )
        end
        local contents, errm = fso:readFile( infoVirginalFile )
        if not contents or errm then
            app:error( "unable to read file - ^1", errm or infoVirginalFile )
        end
        local info = luaText:deserialize( contents, "Info", {} )
        --Debug.lognpp( info )
        --Debug.showLogFile()
        local ok = true
        local function addItem( a, i, title, filename )
            local exe = app:getPref( 'appPath_'..i )
            if str:is( exe ) then
                a[#a + 1] = {
                    title=title,
                    file=filename,
                }
            else
                app:logW( "No app path." )
            end
        end
        local function addItems( items, index )
            local titleBase = app:getPref( 'menuTitle_'..index )
            if not str:is( titleBase ) then
                app:logv( "Title is blank, line item ignored." )
                return
            end
            app:log( titleBase )
            local filename = LrPathUtils.addExtension( "mOpenMostSelected_"..index, "lua" )
            local path = LrPathUtils.child( _PLUGIN.path, filename )
            local contents = str:fmtx( "openIn:whatever( ^1, false )", index )
            local s, m = fso:writeFile( path, contents ) -- default is overwrite.
            if s then
                addItem( items, index, titleBase .. " (Most Selected)", filename )
                if app:getPref( 'allSelToo_'..index ) then
                    local filename = LrPathUtils.addExtension( "mOpenAllSelected_"..index, "lua" )
                    local path = LrPathUtils.child( _PLUGIN.path, filename )
                    contents = str:fmtx( "openIn:whatever( ^1, true )", index )
                    local s, m = fso:writeFile( path, contents ) -- default is overwrite.
                    if s then
                        addItem( items, index, titleBase .. " (All Selected)", filename )
                    else
                        app:logE( m )
                        ok = false
                    end
                else
                    app:logv( "all selected version not defined." )
                end
            else
                app:logE( m )
                ok = false
            end
        end
        local libItems = {}
        local fileItems = {}
        for i=1, self.numOfItems do
            local libMenu = app:getPref( 'libMenu_'..i )
            if libMenu then
                addItems( libItems, i )
            else
                app:logv( "no lib menu" )
            end
            local fileMenu = app:getPref( 'fileMenu_'..i )
            if fileMenu then
                addItems( fileItems, i )
            else
                app:logv( "no file menu" )
            end
        end
        if ok then
            if #libItems > 0 or #fileItems > 0 then
                if #libItems > 0 then
                    info.LrLibraryMenuItems = libItems
                end
                if #fileItems > 0 then
                    info.LrExportMenuItems = fileItems
                end
                local contents = "return " .. luaText:serialize( info )
                local path = LrPathUtils.child( _PLUGIN.path, "Info.lua" )
                local s, m = fso:writeFile( path, contents )
                if s then
                    app:log( "Info.lua written - commission successful." )
                    -- reminder: reload-now method can not re-incorporate changed info-lua file.
                    app:show{ info="Commission successful - plugin must be reloaded.\n \nSo, after dismissing final dialog box(es), click the 'Reload Plug-in' button in the 'Plug-in Author Tools' section of plugin manager.\n \nNote: plugin must be enabled for menu items to be present in File and/or Library Menu -> Plugin Extras (see 'Status' section of plugin manager)." }
                else
                    app:logE( m )
                end
            else
                app:show{ warning="No menu items have been created. At least one item must have 'File Menu' or 'Lib Menu' checked, and have a (non-blank) 'Menu Title', and a valid 'Application Path'.\n \n(if you really don't want to have any items on the file and/or lib menu for opening things, just disable or remove the plugin)" }
            end
        else
            app:logv( "Not creating menu items" )
        end
                    
            
    end, finale=function( call )
        -- 
    end } )
end

return OpenInWhatever