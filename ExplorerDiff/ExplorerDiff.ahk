; ExplorerDiff - ExplorerDiff.ahk
; Context aware file comparing from a single Explorer Hotkey.
; author: eric
; created: 2022 2 2
#include <time>

ExplorerDiff() {
    paths := explorer_get_selected()
    global _ExplorerDiff_WaitForPath
    ; static single_path := ""
    if _ExplorerDiff_CheckDiffApp()
        Return

    if (paths.Length == 2) {
        _ExplorerDiff(paths)
        Return
    }
    if (!paths.Length)
        paths.Push(explorer_get_path())

    if (paths.Length != 1) {
        a2dlg_error("Please select 2 files OR 2 folders exactly!"
            , "ExplorerDiff: Too many paths!")
        Return
    }

    try {
        if (_ExplorerDiff_WaitForPath == paths[1])
            Return
    }
    try {
        if (_ExplorerDiff_WaitForPath) {
            _ExplorerDiff([_ExplorerDiff_WaitForPath, paths[1]])
            _ExplorerDiff_WaitForPath := ""
            Return
        }
    }

    _ExplorerDiff_WaitForPath := paths[1]
    SetTimer _ExplorerDiff_Wait_Call, 30
}

_ExplorerDiff(files) {
    if (path_is_dir(files[1]) AND path_is_dir(files[2])) {
        ExplorerDiff_Run(files)
        Return
    }
    if (path_is_file(files[1]) AND path_is_file(files[2])) {
        ExplorerDiff_Files(files)
        Return
    }

    a2dlg_error("Please select 2 files OR 2 folders exactly!"
        , "ExplorerDiff: File/Folder Mismatch")
}


_ExplorerDiff_Wait_Call() {
    global _ExplorerDiff_WaitForPath
    if (GetKeyState("Escape", "p")) {
        a2tip("ExplorerDiff: Escaped")
        _ExplorerDiff_WaitForPath := ""
    }

    if (!_ExplorerDiff_WaitForPath) {
        a2tip()
        SetTimer _ExplorerDiff_Wait_Call, 0
        Return
    }

    if path_is_dir(_ExplorerDiff_WaitForPath)
        mode := "Folder"
    else
        mode := "File"
    a2tip("ExplorerDiff: Selected " mode ":`n" _ExplorerDiff_WaitForPath "`nSelect another " mode " and press " A_ThisHotkey " again.`nOr hit Escape.")
}


ExplorerDiff_Files(files) {
    file1 := files[1], file2 := files[2]
    size1 := FileGetSize(file1), size2 := FileGetSize(file2)

    time0 := time_unix()
    if (size1 != size2) {
        a2tip("ExplorerDiff: Sizes different ... (" size1 "/" size2 ")")
        ExplorerDiff_Run(files)
        Return
    }

    if (size1 > (ExplorerDiff_MaxSize * 1024 * 1024)) {
        a2tip("ExplorerDiff: Files bigger than " ExplorerDiff_MaxSize " MB ... ")
        ExplorerDiff_Run(files)
        Return
    }

    a2tip("ExplorerDiff: reading file 1 ...", 60)
    contents := FileRead(file1)
    lines1 := []
    Loop parse, contents, "`n"
        lines1.Push(A_LoopField)

    a2tip("ExplorerDiff: reading file 2 ...", 60)
    contents := FileRead(file2)
    lines2 := []
    Loop parse, contents, "`n"
        lines2.Push(A_LoopField)
    contents := ""

    if (lines1.Length != lines2.Length) {
        a2tip("ExplorerDiff: Different line lenghts ... (" lines1.Length "/" lines2.Length ")")
        ExplorerDiff_Run(files)
        Return
    }

    a2tip("ExplorerDiff: Same size, testing line by line ...")
    identical := true
    len := 0
    Loop lines1.Length
    {
        if (lines1[A_Index] != lines2[A_Index]) {
            a2tip("ExplorerDiff: Found Difference on line " A_Index " ... ", 15)
            ExplorerDiff_Run(files)
            Return
        }
        if Mod(A_Index, 10000) == 0
        {
            time_passed := time_unix() - time0
            a2tip("ExplorerDiff: Same size, testing line by line " A_Index)
        }
    }

    a2dlg_info("ExplorerDiff: Files are identical!")
}


ExplorerDiff_Run(files) {
    cmd := '"' . ExplorerDiff_Path . '" "' . files[1] . '" "' . files[2] . '"'
    Run(cmd)
}


_ExplorerDiff_CheckDiffApp() {
    if (ExplorerDiff_Path == "" OR ExplorerDiff_Path == ".") {
        a2dlg_error("No Diff app set! Please open the dialog and set one!"
            , "ExplorerDiff: No Diff app")
        Return true
    }

    if (!FileExist(ExplorerDiff_Path)) {
        a2dlg_error("Unable to find set diff app! The path seems to be invalid!`n`n" ExplorerDiff_Path "`n??"
            , "ExplorerDiff: Diff app path invalid")
        Return true
    }
    Return false
}
