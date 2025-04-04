; ExplorerHotkeys - ExplorerHotkeys_NextPrevDir.ahk
; author: eric
; created: 2025 4 4
#Include <explorer>
#Include <path>

ExplorerHotkeys_NextDir() {
    ExplorerHotkeys_NavigateNextPrevDir(1)
}

ExplorerHotkeys_PrevDir() {
    ExplorerHotkeys_NavigateNextPrevDir(-1)
}

ExplorerHotkeys_NavigateNextPrevDir(amount) {
    this_path := explorer_get_path()
    if !this_path or !path_is_dir(this_path) or this_path == A_Desktop
        return

    parent_path := path_dirname(this_path)
    neighbor_dirs := []
    Loop Files, parent_path "\*", "D"
        neighbor_dirs.Push(A_LoopFileName)

    if neighbor_dirs.Length == 1 {
        a2tip("ExplorerHotkeys: There is only 1 folder in parent directory!")
        return
    }

    this_name := path_basename(this_path)
    this_index := 0
    for name in neighbor_dirs {
        if name != this_name
            continue
        this_index := A_Index
        break
    }

    new_index := this_index + amount
    if new_index == 0 {
        new_index := neighbor_dirs.Length
        msg := "Last of " neighbor_dirs.Length " neighbor folders!"
    }
    else if new_index > neighbor_dirs.Length {
        new_index := 1
        msg := "First of " neighbor_dirs.Length " neighbor folders!"
    } else
        msg := new_index " of " neighbor_dirs.Length " neighbor folders!"

    explorer_set_path(path_join(parent_path, neighbor_dirs[new_index]))
    a2tip("ExplorerHotkeys: " msg)
}