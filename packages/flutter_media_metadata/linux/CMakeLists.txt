cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME flutter_media_metadata)
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CXX_STANDARD_REQUIRED 17)

set(PLUGIN_NAME ${PROJECT_NAME}_plugin)

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}/../cxx/external
)

add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_NAME}.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/../cxx/metadata_retriever.cpp
)

target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/../cxx
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(
  ${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  mediainfo
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(
  ${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
)
target_compile_definitions(
  ${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL
)

set(
  flutter_media_metadata_bundled_libraries
  ""
  PARENT_SCOPE
)
