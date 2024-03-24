import libraw

func librawVersion() -> String {
    String(cString: libraw_version())
}
