@[Include(
    "/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKitLib.h",
    "/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOTypes.h",
    "/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/serial/IOSerialKeys.h",
    "/usr/include/sys/_types/_va_list.h",
    "/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKitKeys.h",
    "/System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFString.h",
    "/System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CoreFoundation.h",
    remove_prefix: false,
    prefix: %w(
        IOServiceMatching
        kIOSerialBSDServiceValue
        IOServiceGetMatchingServices
        kIOMasterPortDefault
        IOIteratorNext
        IORegistryEntryCreateCFProperty
        CFSTR
        kIOCalloutDeviceKey
        kCFAllocatorDefault
        IOObjectRelease
        CFStringGetCString
        kCFStringEncodingASCII
        CFRelease
        IORegistryEntryGetParentEntry
        IORegistryEntrySearchCFProperty
        kIOServicePlane
        kIORegistryIterateRecursively
        kIORegistryIterateParents
        CFStringGetCString
        kCFStringEncodingASCII
        CFNumberGetValue
        kCFNumberIntType
        IOSerialBSDServiceValue
        __CFStringMakeConstantString
        CFStringGetLength
        ))]
@[Link(framework: "IOKit")]
@[Link(framework: "Foundation")]
lib IOKit
 IOSerialBSDServiceValue = kIOSerialBSDServiceValue
end