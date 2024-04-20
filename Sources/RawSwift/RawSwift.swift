import libraw
import Foundation

public class RawSwift {

    public init() {}

    static public func librawVersion() -> String {
        String(cString: libraw_version())
    }

    public func openFile(url: URL) -> libraw_data_t? {
        let data = libraw_init(0)
        libraw_open_file(data, url.path)
        return data?.pointee as? libraw_data_t
    }
}

