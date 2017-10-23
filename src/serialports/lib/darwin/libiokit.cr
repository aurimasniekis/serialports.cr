@[Link(framework: "IOKit")]
@[Link(framework: "Foundation")]
lib IOKit
  type CfAllocatorRef = Void*
  fun cf_release = CFRelease(cf : CfTypeRef)
  alias CfTypeRef = Void*
  KCfStringEncodingAscii = 1536
  fun cf_string_get_length = CFStringGetLength(the_string : CfStringRef) : CfIndex
  type CfStringRef = Void*
  alias CfIndex = LibC::Long
  fun cf_string_get_c_string = CFStringGetCString(the_string : CfStringRef, buffer : LibC::Char*, buffer_size : CfIndex, encoding : CfStringEncoding) : Boolean
  alias UInt32 = LibC::UInt
  alias CfStringEncoding = UInt32
  alias Boolean = UInt8
  fun cf_string_get_c_string_ptr = CFStringGetCStringPtr(the_string : CfStringRef, encoding : CfStringEncoding) : LibC::Char*
  fun __cf_string_make_constant_string = __CFStringMakeConstantString(c_str : LibC::Char*) : CfStringRef
  alias X__DarwinNaturalT = LibC::UInt
  alias X__DarwinMachPortNameT = X__DarwinNaturalT
  alias X__DarwinMachPortT = X__DarwinMachPortNameT
  alias MachPortT = X__DarwinMachPortT
  fun io_object_release = IOObjectRelease(object : IoObjectT) : KernReturnT
  alias IoObjectT = MachPortT
  alias KernReturnT = LibC::Int
  fun io_iterator_next = IOIteratorNext(iterator : IoIteratorT) : IoObjectT
  alias IoIteratorT = IoObjectT
  fun io_service_get_matching_services = IOServiceGetMatchingServices(master_port : MachPortT, matching : CfDictionaryRef, existing : IoIteratorT*) : KernReturnT
  type CfDictionaryRef = Void*
  KIoRegistryIterateRecursively = 1
  KIoRegistryIterateParents = 2
  fun io_registry_entry_create_cf_property = IORegistryEntryCreateCFProperty(entry : IoRegistryEntryT, key : CfStringRef, allocator : CfAllocatorRef, options : IoOptionBits) : CfTypeRef
  alias IoRegistryEntryT = IoObjectT
  alias IoOptionBits = UInt32
  fun io_registry_entry_search_cf_property = IORegistryEntrySearchCFProperty(entry : IoRegistryEntryT, plane : IoNameT, key : CfStringRef, allocator : CfAllocatorRef, options : IoOptionBits) : CfTypeRef
  alias IoNameT = LibC::Char[128]
  fun io_registry_entry_get_parent_entry = IORegistryEntryGetParentEntry(entry : IoRegistryEntryT, plane : IoNameT, parent : IoRegistryEntryT*) : KernReturnT
  fun io_service_matching = IOServiceMatching(name : LibC::Char*) : CfMutableDictionaryRef
  type CfMutableDictionaryRef = Void*
  KCfNumberIntType = 9
  fun cf_number_get_value = CFNumberGetValue(number : CfNumberRef, the_type : CfNumberType, value_ptr : Void*) : Boolean
  type CfNumberRef = Void*
  alias CfNumberType = CfIndex
  $kCFAllocatorDefault : CfAllocatorRef
  $kIOMasterPortDefault : MachPortT
end

