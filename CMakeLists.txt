############################################################################
#
# Copyright (c) 2017 - 2022 PX4 Development Team. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name PX4 nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

#=============================================================================
# CMAKE CODING STANDARD FOR PX4
#
# Structure
# ---------------------------------------------------------------------------
#
# * Common functions should be included in px_base.cmake.
#
# * OS/ board specific fucntions should be include in
#	px_impl_${PX4_PLATFORM}.cmake
#
# Formatting
# ---------------------------------------------------------------------------
#
# * Use hard indents to match the px4 source code.
#
# * All function and script arguments are upper case.
#
# * All local variables are lower case.
#
# * All cmake functions are lowercase.
#
# * For else, endif, endfunction, etc, never put the name of the statement
#
# Functions/Macros
# ---------------------------------------------------------------------------
#
# * Use px4_parse_function_args to parse functions and check for required
#   arguments. Unless there is only one argument in the function and it is clear.
#
# * Never use macros. They allow overwriting global variables and this
#	makes variable declarations hard to locate.
#
# * If a target from add_custom_* is set in a function, explicitly pass it
#	as an output argument so that the target name is clear to the user.
#
# * Avoid use of global variables in functions. Functions in a nested
#	scope may use global variables, but this makes it difficult to
#	reuse functions.
#
# Included CMake Files
# ---------------------------------------------------------------------------
#
# * All variables in config files must have the prefix "config_".
#
# * Never set global variables in an included cmake file,
#	you may only define functions. This excludes config and Toolchain files.
#	This makes it clear to the user when variables are being set or targets
#	are being created.
#
# * Setting a global variable in a CMakeLists.txt file is ok, because
#	each CMakeLists.txt file has scope in the current directory and all
#	subdirectories, so it is not truly global.
#
# * All toolchain files should be included in the cmake
#	directory and named Toolchain-"name".cmake.
#
# Misc
# ---------------------------------------------------------------------------
#
# * If referencing a string variable, don't put it in quotes.
#	Don't do "${PX4_PLATFORM}" STREQUAL "posix",
#	instead type ${PX4_PLATFORM} STREQUAL "posix". This will throw an
#	error when ${PX4_PLATFORM} is not defined instead of silently
#	evaluating to false.
#
#=============================================================================

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

set(PX4_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" CACHE FILEPATH "PX4 source directory" FORCE)
set(PX4_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE FILEPATH "PX4 binary directory" FORCE)

list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/cmake)
include(px4_parse_function_args)

#=============================================================================
# git
#这段代码是在CMakeLists.txt文件中调用git命令获取当前代码库的版本号，并将版本号存储在变量PX4_GIT_TAG中。具体来说，它使用git describe命令来获取最近的标签（tag），并将结果存储在变量PX4_GIT_TAG中。如果没有标签，则使用git describe --always命令获取最近的提交ID。该命令的输出被剥离了尾随的空格，并存储在变量PX4_GIT_TAG中。
include(px4_git)

execute_process(
	COMMAND git describe --exclude ext/* --always --tags
	OUTPUT_VARIABLE PX4_GIT_TAG
	OUTPUT_STRIP_TRAILING_WHITESPACE
	WORKING_DIRECTORY ${PX4_SOURCE_DIR}
	)

# git describe to X.Y.Z version
string(REPLACE "." ";" VERSION_LIST ${PX4_GIT_TAG})

# major version 这段代码的作用是从变量VERSION_LIST中获取索引为0的元素，并将其赋值给变量PX4_VERSION_MAJOR。在这里，VERSION_LIST是一个由字符串PX4_GIT_TAG中的.分隔的版本号列表。这段代码的注释指出了这个代码块的起始和结束位置，这可能是为了在版本控制系统中更容易地查找和比较更改。
list(GET VERSION_LIST 0 PX4_VERSION_MAJOR)
string(REPLACE "v" "" PX4_VERSION_MAJOR ${PX4_VERSION_MAJOR})
# minor version
list(GET VERSION_LIST 1 PX4_VERSION_MINOR)
# patch version 这段代码的作用是从变量VERSION_LIST中获取索引为2的元素，并将其赋值给变量PX4_VERSION_PATCH。在这里，VERSION_LIST是一个由字符串PX4_GIT_TAG中的.分隔的版本号列表。然后，它使用string(REPLACE "-" ";" PX4_VERSION_PATCH ${PX4_VERSION_PATCH})将PX4_VERSION_PATCH中的-替换为;。最后，它从PX4_VERSION_PATCH中获取索引为0的元素，并将其赋值给PX4_VERSION_PATCH。这个过程的目的是从版本号中提取出补丁版本号。
list(GET VERSION_LIST 2 PX4_VERSION_PATCH)
string(REPLACE "-" ";" PX4_VERSION_PATCH ${PX4_VERSION_PATCH})
list(GET PX4_VERSION_PATCH 0 PX4_VERSION_PATCH)

message(STATUS "PX4 version: ${PX4_GIT_TAG} (${PX4_VERSION_MAJOR}.${PX4_VERSION_MINOR}.${PX4_VERSION_PATCH})")

#这段代码定义了一个全局属性PX4_MODULE_LIBRARIES，用于存储所有PX4模块库的列表。这个属性有两个文档字符串，一个是简短的文档字符串，一个是完整的文档字符串，用于描述这个属性的作用和用法。
define_property(GLOBAL PROPERTY PX4_MODULE_LIBRARIES
                 BRIEF_DOCS "PX4 module libs"
                 FULL_DOCS "List of all PX4 module libraries"
                 )

define_property(GLOBAL PROPERTY PX4_KERNEL_MODULE_LIBRARIES
                 BRIEF_DOCS "PX4 kernel side module libs"
                 FULL_DOCS "List of all PX4 kernel module libraries"
                 )

define_property(GLOBAL PROPERTY PX4_MODULE_PATHS
                 BRIEF_DOCS "PX4 module paths"
                 FULL_DOCS "List of paths to all PX4 modules"
                 )
define_property(GLOBAL PROPERTY PX4_SRC_FILES
                 BRIEF_DOCS "src files from all PX4 modules & libs"
                 FULL_DOCS "SRC files from px4_add_{module,library}"
                 )

#=============================================================================
# configuration
#

include(px4_add_module)
set(config_module_list)#这段代码定义了一个空的CMake变量config_module_list。这个变量可以用来存储PX4模块的列表
set(config_kernel_list)

# Find Python 查找python解释器
find_package(PythonInterp 3)
# We have a custom error message to tell users how to install python3.
if(NOT PYTHONINTERP_FOUND)
	message(FATAL_ERROR "Python 3 not found. Please install Python 3:\n"
		"    Ubuntu: sudo apt install python3 python3-dev python3-pip\n"
		"    macOS: brew install python")
endif()

option(PYTHON_COVERAGE "Python code coverage" OFF) #`PYTHON_COVERAGE` 选项被定义为 OFF。这意味着 Python 代码覆盖率检查功能将被禁用
#如果 `PYTHON_COVERAGE` 选项被设置为 ON，则会将 `PYTHON_EXECUTABLE` 变量设置为 `coverage run -p`。这将启用 Python 代码覆盖率检查功能。如果 `PYTHON_COVERAGE` 选项被设置为 OFF，则 `PYTHON_EXECUTABLE` 变量将保持不变，不会启用 Python 代码覆盖率检查功能。
if(PYTHON_COVERAGE)
	message(STATUS "python coverage enabled")
	set(PYTHON_EXECUTABLE coverage run -p)
endif()

include(px4_config)
include(kconfig)
message(STATUS "PX4 config: ${PX4_CONFIG}")
message(STATUS "PX4 platform: ${PX4_PLATFORM}")

#这段代码用于在 CLion 集成开发环境中禁用 GCC 毒药。这可以避免在 NuttX 上出现问题，并确保项目能够成功编译。`add_definitions` 命令是 CMake 中的一个工具，用于向编译器添加宏定义。`if` 语句是 CMake 中的一个基本工具，用于根据条件执行不同的命令。
if($ENV{CLION_IDE})
	# CLion automatically executes some compiler commands after configuring the
	# project. This would fail on NuttX, as visibility.h tries to (indirectly)
	# include nuttx/config.h, which at that point does not exist yet
	add_definitions(-DPX4_DISABLE_GCC_POISON)#`add_definitions` 命令是 CMake 中的一个工具，用于向编译器添加宏定义
endif()

if(${PX4_PLATFORM} STREQUAL "posix") #`if` 语句检查 `${PX4_PLATFORM}` 变量的值是否等于字符串 `"posix"`。
	if(ENABLE_LOCKSTEP_SCHEDULER)
	# `if` 语句，用于检查 `ENABLE_LOCKSTEP_SCHEDULER` 变量是否被设置。如果被设置，则使用 `add_definitions` 命令将 `-DENABLE_LOCKSTEP_SCHEDULER` 宏定义添加到编译器选项中
		add_definitions(-DENABLE_LOCKSTEP_SCHEDULER)
		message(STATUS "PX4 lockstep: enabled")
	else()
		message(STATUS "PX4 lockstep: disabled")
	endif()
endif()

# external modules
set(EXTERNAL_MODULES_LOCATION "" CACHE STRING "External modules source location")

if(NOT EXTERNAL_MODULES_LOCATION STREQUAL "")
#如果 `EXTERNAL_MODULES_LOCATION` 变量的值不等于空字符串，则 `get_filename_component` 命令将变量的绝对路径存储在 `EXTERNAL_MODULES_LOCATION` 变量中。`get_filename_component` 命令用于获取文件路径的各个组成部分，例如目录名、文件名和扩展名等。
	get_filename_component(EXTERNAL_MODULES_LOCATION "${EXTERNAL_MODULES_LOCATION}" ABSOLUTE)
endif()

#`PX4_MODULE_CONFIG_FILES` 属性被设置为一个空值。这意味着没有任何模块配置文件被定义。如果需要定义模块配置文件，可以将 `PX4_MODULE_CONFIG_FILES` 属性设置为相应的文件路径。
set_property(GLOBAL PROPERTY PX4_MODULE_CONFIG_FILES)

include(platforms/${PX4_PLATFORM}/cmake/px4_impl_os.cmake)
list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/platforms/${PX4_PLATFORM}/cmake)

if(EXISTS "${PX4_SOURCE_DIR}/platforms/${PX4_PLATFORM}/cmake/init.cmake")
	include(init)
endif()

#=============================================================================
# project definition
#`project` 命令被用于定义一个名为 `px4` 的项目，并指定该项目支持 C++、C 和汇编语言。这意味着在编写代码时，可以使用这些语言的特性和语法
project(px4 CXX C ASM)

# CMake build type (Debug Release RelWithDebInfo MinSizeRel Coverage)
if(NOT CMAKE_BUILD_TYPE)
	if(${PX4_PLATFORM} STREQUAL "nuttx")
		set(PX4_BUILD_TYPE "MinSizeRel")
	else()
		set(PX4_BUILD_TYPE "RelWithDebInfo")
	endif()

	set(CMAKE_BUILD_TYPE ${PX4_BUILD_TYPE} CACHE STRING "Build type" FORCE)
endif()

if((CMAKE_BUILD_TYPE STREQUAL "Debug") OR (CMAKE_BUILD_TYPE STREQUAL "Coverage"))
	set(MAX_CUSTOM_OPT_LEVEL -O0)
elseif(CMAKE_BUILD_TYPE MATCHES "Sanitizer")
	set(MAX_CUSTOM_OPT_LEVEL -O1)
elseif(CMAKE_BUILD_TYPE MATCHES "Release")
	set(MAX_CUSTOM_OPT_LEVEL -O3)
else()
	if(px4_constrained_flash_build)
		set(MAX_CUSTOM_OPT_LEVEL -Os)
	else()
		set(MAX_CUSTOM_OPT_LEVEL -O2)
	endif()
endif()

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release;RelWithDebInfo;MinSizeRel;Coverage;AddressSanitizer;UndefinedBehaviorSanitizer")
message(STATUS "cmake build type: ${CMAKE_BUILD_TYPE}")

# Check if LTO option and check if toolchain supports it
if(LTO)
    include(CheckIPOSupported)
    check_ipo_supported()
    message(AUTHOR_WARNING "LTO enabled: LTO is highly experimental and should not be used in production")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

set(package-contact "px4users@googlegroups.com")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PX4_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PX4_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PX4_BINARY_DIR})

#=============================================================================

# gold linker - use if available (posix only for now)
if(${PX4_PLATFORM} STREQUAL "posix")
	include(CMakeDependentOption)
	CMAKE_DEPENDENT_OPTION(USE_LD_GOLD
			"Use GNU gold linker" ON
			"NOT WIN32;NOT APPLE" OFF
	)

	if(USE_LD_GOLD)
		execute_process(COMMAND ${CMAKE_C_COMPILER} -fuse-ld=gold -Wl,--version ERROR_QUIET OUTPUT_VARIABLE LD_VERSION)
		if("${LD_VERSION}" MATCHES "GNU gold")
			set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=gold")
			set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=gold")
		else()
			set(USE_LD_GOLD OFF)
		endif()
	endif()
endif()

#=============================================================================

# Setup install paths
if(${PX4_PLATFORM} STREQUAL "posix")
	# This makes it possible to dynamically load code which depends on symbols
	# inside the px4 executable.
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
	set(CMAKE_ENABLE_EXPORTS ON)

	if(CMAKE_BUILD_TYPE MATCHES "Coverage")
		include(coverage)#coverage` 模块用于生成代码覆盖率报告，以帮助开发人员识别测试用例中未覆盖的代码。
	endif()

	include(sanitizers)#`sanitizers` 模块用于在编译时启用内存和地址检查器。这些检查器可以帮助开发人员识别内存泄漏和内存访问错误等问题。

	# Define GNU standard installation directories
	include(GNUInstallDirs)#`GNUInstallDirs` 模块用于定义 GNU 标准的安装目录。这些目录包括 `CMAKE_INSTALL_BINDIR`、`CMAKE_INSTALL_LIBDIR`、`CMAKE_INSTALL_INCLUDEDIR` 和 `CMAKE_INSTALL_DATADIR` 等。

	if (NOT CMAKE_INSTALL_PREFIX)
		set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install path prefix" FORCE)
	endif()
endif()

include(ccache)#`ccache` 模块用于启用 ccache 缓存。ccache 是一个编译器缓存，可以加快编译速度。它可以在编译时缓存编译器输出，以便在下次编译时重用。这个模块的作用是在编译时启用 ccache 缓存。

#=============================================================================
# get chip and chip manufacturer
#`px4_os_determine_build_chip()` 函数被调用，用于获取芯片和芯片制造商的信息。如果 `PX4_CHIP_MANUFACTURER` 变量未被设置，则 `if` 语句将输出一条致命错误消息，指示 `px4_os_determine_build_chip()` 函数需要设置 `PX4_CHIP_MANUFACTURER` 变量。同样，如果 `PX4_CHIP` 变量未被设置，则 `if` 语句将输出一条致命错误消息，指示 `px4_os_determine_build_chip()` 函数需要设置 `PX4_CHIP` 变量。
px4_os_determine_build_chip()
if(NOT PX4_CHIP_MANUFACTURER)
	message(FATAL_ERROR "px4_os_determine_build_chip() needs to set PX4_CHIP_MANUFACTURER")
endif()
if(NOT PX4_CHIP)
	message(FATAL_ERROR "px4_os_determine_build_chip() needs to set PX4_CHIP")
endif()

#=============================================================================
# build flags
#
include(px4_add_common_flags) #包含px4_add_common_flags.cmake模块
px4_add_common_flags()#调用px4_add_common_flags函数
px4_os_add_flags()#调用px4_os_add_flags函数

#=============================================================================
# board cmake init (optional)
#
if(EXISTS ${PX4_BOARD_DIR}/cmake/init.cmake)
	include(${PX4_BOARD_DIR}/cmake/init.cmake)
endif()

#=============================================================================
# message, and airframe generation
#
include(px4_metadata)

add_subdirectory(msg EXCLUDE_FROM_ALL)#`add_subdirectory` 命令被用于添加一个名为 "msg" 的子目录。这意味着在 "msg" 子目录中，可以编写另一个 CMakeLists.txt 文件，并在其中定义和构建其他目标。此外，`EXCLUDE_FROM_ALL` 参数用于指定 "msg" 目录中的目标不应包含在默认的构建目标中。

px4_generate_airframes_xml(BOARD ${PX4_BOARD})

#=============================================================================
# external projects
#
set(ep_base ${PX4_BINARY_DIR}/external)
set_property(DIRECTORY PROPERTY EP_BASE ${ep_base})

# add external project install folders to build
# add the directories so cmake won't warn
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base})
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install/lib)
link_directories(${ep_base}/Install/lib)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install/include)
include_directories(${ep_base}/Install/include)

#=============================================================================
# external modules
#
set(external_module_paths)
if (NOT EXTERNAL_MODULES_LOCATION STREQUAL "")
	message(STATUS "External modules: ${EXTERNAL_MODULES_LOCATION}")
	add_subdirectory("${EXTERNAL_MODULES_LOCATION}/src" external_modules)

	foreach(external_module ${config_module_list_external})
		add_subdirectory(${EXTERNAL_MODULES_LOCATION}/src/${external_module} external_modules/${external_module})
		list(APPEND external_module_paths ${EXTERNAL_MODULES_LOCATION}/src/${external_module})
	endforeach()
endif()

#=============================================================================
# Testing - Automatic unit and integration testing with CTest
#

# optionally enable cmake testing (supported only on posix)
option(CMAKE_TESTING "Configure test targets" OFF)#option` 命令用于定义一个名为 `CMAKE_TESTING` 的选项，并将其默认值设置为假。
if(${PX4_CONFIG} STREQUAL "px4_sitl_test")#在 `PX4_CONFIG` 变量的值等于 "px4_sitl_test" 时，`set` 命令用于将 `CMAKE_TESTING` 变量的值设置为真。这意味着当 `PX4_CONFIG` 变量的值为 "px4_sitl_test" 时，将启用 CMake 测试。
	set(CMAKE_TESTING ON)
endif()
if(CMAKE_TESTING)
	include(CTest) # sets BUILD_TESTING variable
endif()

# enable test filtering to run only specific tests with the ctest -R regex functionality
set(TESTFILTER "" CACHE STRING "Filter string for ctest to selectively only run specific tests (ctest -R)")

# if testing is enabled download and configure gtest
list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/cmake/gtest/)
include(px4_add_gtest)
if(BUILD_TESTING)
	include(gtest)#`include` 命令用于包含 `gtest` 模块。`gtest` 模块用于下载和配置 Google Test 框架。Google Test 是一个 C++ 测试框架，用于编写单元测试和集成测试。Google Test 框架的源代码存储在 `cmake/gtest` 目录中。

	add_custom_target(test_results
			COMMAND GTEST_COLOR=1 ${CMAKE_CTEST_COMMAND} --output-on-failure -T Test -R ${TESTFILTER} USES_TERMINAL
			DEPENDS
				px4
				examples__dyn_hello
			USES_TERMINAL
			COMMENT "Running tests"
			WORKING_DIRECTORY ${PX4_BINARY_DIR})
	set_target_properties(test_results PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif()


#=============================================================================
# subdirectories
#add_library` 命令用于定义一个库，并指定其源文件和属性。在这个例子中，`add_library` 命令被用于定义两个接口库，分别为 "parameters_interface" 和 "kernel_parameters_interface"。接口库是一种特殊类型的库，它不包含实际的代码，而是包含一组函数或变量的声明。接口库通常用于定义公共接口，以便其他库或应用程序可以使用这些接口。在这个例子中，"parameters_interface" 和 "kernel_parameters_interface" 接口库用于定义参数和内核参数的公共接口。
add_library(parameters_interface INTERFACE)
add_library(kernel_parameters_interface INTERFACE)

include(px4_add_library)
add_subdirectory(src/lib EXCLUDE_FROM_ALL) #`add_subdirectory` 命令被用于添加一个名为 "src/lib" 的子目录，`EXCLUDE_FROM_ALL` 参数用于指定 "src/lib" 目录中的目标不应包含在默认的构建目标中。

add_subdirectory(platforms/${PX4_PLATFORM}/src/px4)
add_subdirectory(platforms EXCLUDE_FROM_ALL)

if(EXISTS "${PX4_BOARD_DIR}/CMakeLists.txt")
	add_subdirectory(${PX4_BOARD_DIR})
endif()

#`foreach` 命令用于迭代一个列表，并执行一系列命令。在这个例子中，`foreach` 命令被用于迭代 `config_module_list` 列表，并为列表中的每个模块添加一个子目录。
foreach(module ${config_module_list})
	add_subdirectory(src/${module})
endforeach()

# add events lib after modules and libs as it needs to know all source files (PX4_SRC_FILES)
add_subdirectory(src/lib/events EXCLUDE_FROM_ALL)
# metadata needs PX4_MODULE_CONFIG_FILES
add_subdirectory(src/lib/metadata EXCLUDE_FROM_ALL)

# must be the last module before firmware
add_subdirectory(src/lib/parameters EXCLUDE_FROM_ALL)

#如果 `PX4_PLATFORM` 变量的值等于 "nuttx" 且 `CONFIG_BUILD_FLAT` 变量的值为假，则 `parameters_interface` 接口库将与 `usr_parameters` 库进行链接，`kernel_parameters_interface` 接口库将与 `parameters` 库进行链接。否则，`parameters_interface` 接口库将与 `parameters` 库进行链接。
if(${PX4_PLATFORM} STREQUAL "nuttx" AND NOT CONFIG_BUILD_FLAT)
	target_link_libraries(parameters_interface INTERFACE usr_parameters)
	target_link_libraries(kernel_parameters_interface INTERFACE parameters)
else()
	target_link_libraries(parameters_interface INTERFACE parameters)
endif()

# firmware added last to generate the builtin for included modules
add_subdirectory(platforms/${PX4_PLATFORM})

#=============================================================================
# uORB graph generation: add a custom target 'uorb_graph'
#
set(uorb_graph_config ${PX4_BOARD})

set(graph_module_list "")
foreach(module ${config_module_list})
	set(graph_module_list "${graph_module_list}" "--src-path" "src/${module}")
endforeach()

#在 `add_custom_command` 命令中，`${uorb_graph_config}` 表示输出文件的路径，`${PYTHON_EXECUTABLE}` 表示 Python 解释器的路径，`${PX4_SOURCE_DIR}` 表示项目的根目录。`${graph_module_list}` 是一个变量，表示要包含在 uORB 图中的模块列表。`--src-path`、`--merge-depends`、`--exclude-path` 和 `--file` 是 Python 脚本的命令行参数。
#在 `add_custom_target` 命令中，"uorb_graph" 是自定义目标的名称，`${uorb_graph_config}` 是自定义命令的输出文件。这意味着当执行 "uorb_graph" 目标时，将自动执行 "uorb_graph_config" 命令。
#总的来说，这段代码用于定义一个自定义命令和一个自定义目标，用于生成 uORB 图
add_custom_command(OUTPUT ${uorb_graph_config}
	COMMAND ${PYTHON_EXECUTABLE} ${PX4_SOURCE_DIR}/Tools/uorb_graph/create.py
		${graph_module_list} --src-path src/lib
		--merge-depends
		--exclude-path src/examples
		--exclude-path src/lib/parameters # FIXME: enable & fix
		--file ${PX4_SOURCE_DIR}/Tools/uorb_graph/graph_${uorb_graph_config}
	WORKING_DIRECTORY ${PX4_SOURCE_DIR}
	COMMENT "Generating uORB graph"
)
add_custom_target(uorb_graph DEPENDS ${uorb_graph_config})


include(bloaty)#`bloaty` 模块用于生成二进制文件的大小报告。这个模块的作用是在编译时启用 bloaty。`bloaty` 是一个二进制文件大小分析器，用于分析二进制文件的大小。它可以帮助开发人员识别二进制文件中的冗余代码，以便优化二进制文件的大小。


include(doxygen)#`doxygen` 模块用于生成 Doxygen 文档。Doxygen 是一个文档生成器，用于生成软件文档。它可以从源代码中提取注释，并生成 HTML、PDF 和 LaTeX 等格式的文档。这个模块的作用是在编译时启用 Doxygen。
include(metadata)#`metadata` 模块用于生成元数据文件。元数据文件包含了 PX4 项目的元数据，例如项目的版本号、构建时间和构建平台等。这个模块的作用是在编译时启用元数据文件。
include(package)#`package` 模块用于生成软件包。软件包是一个压缩文件，包含了软件的二进制文件和其他资源。这个模块的作用是在编译时启用软件包。

# install python requirements using configured python
add_custom_target(install_python_requirements
	COMMAND ${PYTHON_EXECUTABLE} -m pip install --requirement ${PX4_SOURCE_DIR}/Tools/setup/requirements.txt
	DEPENDS ${PX4_SOURCE_DIR}/Tools/setup/requirements.txt
	USES_TERMINAL
)

if(EXISTS "${PX4_SOURCE_DIR}/platforms/${PX4_PLATFORM}/cmake/finalize.cmake")
	include(finalize)#`finalize` 模块用于在构建过程的最后阶段执行一些操作。这个模块的作用是在构建过程的最后阶段执行 `finalize.cmake` 脚本。
endif()
