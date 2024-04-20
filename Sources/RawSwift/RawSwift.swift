import libraw
import Foundation

public class RawSwift {

    public init() {}

    static public func librawVersion() -> String {
        String(cString: libraw_version())
    }

    public func openFile(url: URL) {
        let data = libraw_init(0)
        let result = libraw_open_file(data, url.path)
        print(result)
        print(data?.pointee.params)
    }
}

