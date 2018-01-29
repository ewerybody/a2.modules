callExplorer()
{
    global callExplorer_path
    IfNotExist, %callExplorer_path%
    {
        MsgBox, 16, ExplorerHotkeys Error, The call Explorer-path set in ExplorerHotkeys is inexistent:`n`n  %callExplorer_path%`n`nMaybe the directory was deleted? Please make sure the path exists or choose an existing one in the dialog!
        Run, "C:\\"
        Return
    }
 	Run, %callExplorer_path%
}
