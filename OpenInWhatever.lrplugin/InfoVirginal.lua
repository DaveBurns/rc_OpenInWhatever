--[[
        Info.lua
--]]

return {
    appName = "Open In Whatever",
    author = "Rob Cole",
    authorsWebsite = "www.robcole.com",
    donateUrl = "http://www.robcole.com/Rob/Donate",
    platforms = { 'Windows', 'Mac' },
    pluginId = "com.robcole.lightroom.OpenInWhatever",
    xmlRpcUrl = "http://www.robcole.com/Rob/_common/cfpages/XmlRpc.cfm",
    LrPluginName = "rc Open In Whatever",
    LrSdkMinimumVersion = 3.0,
    LrSdkVersion = 5.0,
    LrPluginInfoUrl = "http://www.robcole.com/Rob/ProductsAndServices/OpenInWhateverLrPlugin",
    LrPluginInfoProvider = "OpenInWhateverManager.lua",
    LrToolkitIdentifier = "com.robcole.OpenInWhatever",
    LrInitPlugin = "Init.lua",
    LrShutdownPlugin = "Shutdown.lua",
    LrMetadataTagsetFactory = "Tagsets.lua",
    LrHelpMenuItems = {
        {
            title = "General Help",
            file = "mHelp.lua",
        },
    },
    VERSION = { major=1, minor=2, revision=0, build=0, },
}
