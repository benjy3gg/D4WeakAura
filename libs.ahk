iniObj(iniFile) {
    ini := []
    IniRead, sections,% inifile
    for number, section in StrSplit(sections,"`n") {
        IniRead, keys  ,% inifile,% section
        ini[section] := []
        for number, key in StrSplit(keys,"`n") {
            ini[section][StrSplit(key,"=").1] := StrSplit(key,"=").2
            }
        }
    Return ini
}