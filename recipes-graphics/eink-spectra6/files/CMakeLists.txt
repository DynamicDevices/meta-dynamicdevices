cmake_minimum_required(VERSION 3.10)
project(eink-spectra6 VERSION 1.0.0)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# Check for libgpiod (optional)
pkg_check_modules(LIBGPIOD libgpiod)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Source files
set(SOURCES
    eink-driver-stub.c
)

set(HEADERS
    eink-driver-stub.h
)

# Create library
add_library(el133uf1 SHARED ${SOURCES})
set_target_properties(el133uf1 PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
)

# Create test executable
add_executable(el133uf1_test eink-driver-stub.c)
target_compile_definitions(el133uf1_test PRIVATE -DTEST_APPLICATION)

# Create demo executable (alias to test for now)
add_executable(el133uf1_demo eink-driver-stub.c)
target_compile_definitions(el133uf1_demo PRIVATE -DTEST_APPLICATION)

# Link libraries if available
if(LIBGPIOD_FOUND)
    target_link_libraries(el133uf1 ${LIBGPIOD_LIBRARIES})
    target_include_directories(el133uf1 PRIVATE ${LIBGPIOD_INCLUDE_DIRS})
    target_compile_definitions(el133uf1 PRIVATE HAVE_LIBGPIOD)
    
    target_link_libraries(el133uf1_test ${LIBGPIOD_LIBRARIES})
    target_include_directories(el133uf1_test PRIVATE ${LIBGPIOD_INCLUDE_DIRS})
    target_compile_definitions(el133uf1_test PRIVATE HAVE_LIBGPIOD)
    
    target_link_libraries(el133uf1_demo ${LIBGPIOD_LIBRARIES})
    target_include_directories(el133uf1_demo PRIVATE ${LIBGPIOD_INCLUDE_DIRS})
    target_compile_definitions(el133uf1_demo PRIVATE HAVE_LIBGPIOD)
endif()

# Install targets
install(TARGETS el133uf1 el133uf1_test el133uf1_demo
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${HEADERS}
    DESTINATION include/el133uf1
)

# Install documentation
install(FILES LICENSE
    DESTINATION share/doc/el133uf1
)
