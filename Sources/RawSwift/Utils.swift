import libraw
import Foundation

public class Utils {

    public init() {}

    static public func librawVersion() -> String {
        String(cString: libraw_version())
    }

}

