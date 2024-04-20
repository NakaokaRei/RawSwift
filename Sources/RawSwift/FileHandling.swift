import Foundation
import libraw

public class FileHandling {

    public init() {}

    public static func initLibRawData() -> UnsafeMutablePointer<libraw_data_t> {
        libraw_init(0)
    }

    public func openFile(url: URL, rawData: UnsafeMutablePointer<libraw_data_t>) {
        let result = libraw_open_file(rawData, url.path)
        print(result)
        print(rawData.pointee)
    }
}
