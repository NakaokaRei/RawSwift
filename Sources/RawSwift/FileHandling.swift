import Foundation
import libraw

public class FileHandling {

    public init() {}

    public static func initLibRawData() -> UnsafeMutablePointer<libraw_data_t> {
        libraw_init(0)
    }

    public func openFile(url: URL, rawdata: UnsafeMutablePointer<libraw_data_t>) -> LibRaw_errors {
        let result = libraw_open_file(rawdata, url.path)

        if (result != LIBRAW_SUCCESS.rawValue) {
            if #available(OSX 11.0, *) {
               let errorMessage = String(cString: libraw_strerror(result))
                print("LibRaw error: \(errorMessage)")
            }
            libraw_close(rawdata)
        }
        // let data = UnsafeMutableRawPointer( Unmanaged<libraw_data_t.self>.fromOpaque(rawdata!).takeUnretainedValue()
        return LibRaw_errors.init(result)
    }
}
