cmake_minimum_required(VERSION 3.4.1)

file(GLOB_RECURSE cppPaths "../ios/ShallowBlue/src/*.cpp")
add_library(
  shallowblue
  SHARED
  ../ios/FlutterShallowBlue/ffi.cpp
  ${cppPaths}
)

