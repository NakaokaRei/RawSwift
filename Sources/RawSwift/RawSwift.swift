import libraw

public func librawVersion() -> String {
    String(cString: libraw_version())
}
