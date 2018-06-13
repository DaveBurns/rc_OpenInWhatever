--[[
        OpenInWhateverManager.lua
--]]


local OpenInWhateverManager, dbg = Manager:newClass{ className='OpenInWhateverManager' }



--[[
        Constructor for extending class.
--]]
function OpenInWhateverManager:newClass( t )
    return Manager.newClass( self, t )
end



--[[
        Constructor for new instance object.
--]]
function OpenInWhateverManager:new( t )
    return Manager.new( self, t )
end



--- Initialize global preferences.
--
function OpenInWhateverManager:_initGlobalPrefs()
    -- Instructions: delete the following line (or set property to nil) if this isn't an export plugin.
    --fprops:setPropertyForPlugin( _PLUGIN, 'exportMgmtVer', "2" ) -- a little add-on here to support export management. '1' is legacy (rc-common-modules) mgmt.
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initGlobalPref( 'exifToolApp', "" )
    -- app:initGlobalPref( 'mogrifyApp', "" )
    -- app:initGlobalPref( 'sqliteApp', "" )
    Manager._initGlobalPrefs( self )
end



--- Initialize local preferences for preset.
--
function OpenInWhateverManager:_initPrefs( presetName )
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initPref( 'exifToolApp', "", presetName )
    -- app:initPref( 'mogrifyApp', "", presetName )
    -- app:initPref( 'sqliteApp', "", presetName )
    -- *** Instructions: delete this line if no async init or continued background processing:
    --app:initPref( 'background', false, presetName ) -- true to support on-going background processing, after async init (auto-update most-sel photo).
    -- *** Instructions: delete these 3 if not using them:
    --app:initPref( 'processTargetPhotosInBackground', false, presetName )
    --app:initPref( 'processFilmstripPhotosInBackground', false, presetName )
    --app:initPref( 'processAllPhotosInBackground', false, presetName )
    for i = 1, openIn.numOfItems do
        app:initPref( 'fileMenu_'..i, true, presetName )
        app:initPref( 'libMenu_'..i, false, presetName )
        app:initPref( 'menuTitle_'..i, "", presetName )
        app:initPref( 'appPath_'..i, "", presetName )
        app:initPref( 'allSelToo_'..i, false, presetName )
        app:initPref( 'cmdLineParams_'..i, "", presetName )
    end
    Manager._initPrefs( self, presetName )
end



--- Start of plugin manager dialog.
-- 
function OpenInWhateverManager:startDialogMethod( props )
    -- *** Instructions: uncomment if you use these apps and their exe is bound to ordinary property table (not prefs).
    Manager.startDialogMethod( self, props ) -- adds observer to all props.
end



--- Preference change handler.
--
--  @usage      Handles preference changes.
--              <br>Preferences not handled are forwarded to base class handler.
--  @usage      Handles changes that occur for any reason, one of which is user entered value when property bound to preference,
--              <br>another is preference set programmatically - recursion guarding is essential.
--
function OpenInWhateverManager:prefChangeHandlerMethod( _props, _prefs, key, value )
    Manager.prefChangeHandlerMethod( self, _props, _prefs, key, value )
end



--- Property change handler.
--
--  @usage      Properties handled by this method, are either temporary, or
--              should be tied to named setting preferences.
--
function OpenInWhateverManager:propChangeHandlerMethod( props, name, value, call )
    if app.prefMgr and (app:getPref( name ) == value) then -- eliminate redundent calls.
        -- Note: in managed cased, raw-pref-key is always different than name.
        -- Note: if preferences are not managed, then depending on binding,
        -- app-get-pref may equal value immediately even before calling this method, in which case
        -- we must fall through to process changes.
        return
    end
    -- *** Instructions: strip this if not using background processing:
    if name == 'background' then
        app:setPref( 'background', value )
        if value then
            local started = background:start()
            if started then
                app:show( "Auto-check started." )
            else
                app:show( "Auto-check already started." )
            end
        elseif value ~= nil then
            app:call( Call:new{ name = 'Stop Background Task', async=true, guard=App.guardVocal, main=function( call )
                local stopped
                repeat
                    stopped = background:stop( 10 ) -- give it some seconds.
                    if stopped then
                        app:logVerbose( "Auto-check was stopped by user." )
                        app:show( "Auto-check is stopped." ) -- visible status wshould be sufficient.
                    else
                        if dialog:isOk( "Auto-check stoppage not confirmed - try again? (auto-check should have stopped - please report problem; if you cant get it to stop, try reloading plugin)" ) then
                            -- ok
                        else
                            break
                        end
                    end
                until stopped
            end } )
        end
    else
        -- Note: preference key is different than name.
        Manager.propChangeHandlerMethod( self, props, name, value, call )
    end
end



--- Sections for bottom of plugin manager dialog.
-- 
function OpenInWhateverManager:sectionsForBottomOfDialogMethod( vf, props)

    local appSection = {}
    if app.prefMgr then
        appSection.bind_to_object = props
    else
        appSection.bind_to_object = prefs
    end
    
	appSection.title = app:getAppName() .. " Settings"
	appSection.synopsis = bind{ key='presetName', object=prefs }

	appSection.spacing = vf:label_spacing()

	appSection[#appSection + 1] = vf:row {
	    vf:static_text {
	        title = "File\nMenu",
	        width = share 'col_1',
	    },
	    vf:static_text {
	        title = "Lib\nMenu",
	        width = share 'col_2',
	    },
	    vf:static_text {
	        title = "All\nSel",
	        width = share 'col_3',
	    },
	    vf:static_text {
	        title = "Menu Title",
	        width_in_chars=10,
	    },
	    vf:static_text {
	        title = "Application Path",
	        width_in_chars=20,
	    },
	    vf:spacer{ width=share 'btn_1' },
	    vf:static_text {
	        title = "Parameters\n(cmd-line)",
	    },
	}
    
	for i = 1, openIn.numOfItems do
    	appSection[#appSection + 1] = vf:row {
    	    vf:checkbox {
    	        title = "",
    	        width = share 'col_1',
    	        value = bind( 'fileMenu_'..i ),
    	    },
    	    vf:checkbox {
    	        title = "",
    	        width = share 'col_2',
    	        value = bind( 'libMenu_'..i ),
    	    },
    	    vf:checkbox {
    	        title = "",
    	        width = share 'col_3',
    	        value = bind( 'allSelToo_'..i ),
    	    },
    	    vf:edit_field {
    	        value = bind( 'menuTitle_'..i ),
    	        width_in_chars = 10,
    	    },
    	    vf:edit_field {
    	        value = bind( 'appPath_'..i ),
    	        width_in_chars = 20,
    	    },
    	    vf:push_button {
    	        title="Browse",
    	        action = function( button )
    	            dia:selectFile( {
    	                title = "Select executable file",
    	                fileTypes = nil, -- allow any file type.
    	            }, props, "appPath_"..i )
    	        end,
    	        width = share 'btn_1',
    	    },
    	    vf:edit_field {
    	        value = bind( 'cmdLineParams_'..i ),
    	        width_in_chars = 5,
    	    },
    	}
	end
	
  	appSection[#appSection + 1] = vf:row {
	    vf:push_button {
	        title="Commit",
	        action = function( button )
	            openIn:commit( 'commit', "Commit" )
	        end,
	    },
	    vf:static_text {
	        title = "Process form entries above.",
	    },
	}

    if not app:isRelease() then
    	appSection[#appSection + 1] = vf:spacer{ height = 20 }
    	appSection[#appSection + 1] = vf:static_text{ title = 'For plugin author only below this line:' }
    	appSection[#appSection + 1] = vf:separator{ fill_horizontal = 1 }
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:edit_field {
    				value = bind( "testData" ),
    			},
    			vf:static_text {
    				title = str:format( "Test data" ),
    			},
    		}
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:push_button {
    				title = "Test",
    				action = function( button )
    				    app:call( Call:new{ name='Test', main = function( call )
                            app:show( { info="^1: ^2" }, str:to( app:getGlobalPref( 'presetName' ) or 'Default' ), app:getPref( 'testData' ) )
                        end } )
    				end
    			},
    			vf:static_text {
    				title = str:format( "Perform tests." ),
    			},
    		}
    end
		
    local sections = Manager.sectionsForBottomOfDialogMethod ( self, vf, props ) -- fetch base manager sections.
    if #appSection > 0 then
        tab:appendArray( sections, { appSection } ) -- put app-specific prefs after.
    end
    return sections
end



return OpenInWhateverManager
-- the end.