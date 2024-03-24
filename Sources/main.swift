import libraw

let cStringArray: UnsafeMutablePointer<UnsafePointer<CChar>?>! = libraw_cameraList()
var stringArray: [String] = []

var currentIndex = 0
while let cString = cStringArray[currentIndex] {
    stringArray.append(String(cString: cString))
    currentIndex += 1
}

print(stringArray)
