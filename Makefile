############################################################################
#
# Copyright (c) 2015 - 2020 PX4 Development Team. All rights reserved.
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

# Enforce the presence of the GIT repository
#
# We depend on our submodules, so we have to prevent attempts to
# compile without it being present.
ifeq ($(wildcard .git),)
    $(error YOU HAVE TO USE GIT TO DOWNLOAD THIS REPOSITORY. ABORTING.)
endif

# Help
# --------------------------------------------------------------------
# Don't be afraid of this makefile, it is just passing
# arguments to cmake to allow us to keep the wiki pages etc.
# that describe how to build the px4 firmware
# the same even when using cmake instead of make.
#
# Example usage:
#
# make px4_fmu-v2_default 			(builds)
# make px4_fmu-v2_default upload 	(builds and uploads)
# make px4_fmu-v2_default test 		(builds and tests)
#
# This tells cmake to build the nuttx px4_fmu-v2 default config in the
# directory build/px4_fmu-v2_default and then call make
# in that directory with the target upload.

# explicity set default build target在 Makefile 中，"all" 目标是默认目标。这意味着当用户在命令行中输入 "make" 命令时，将自动构建 "all" 目标。在这个例子中，"all" 目标只是一个伪目标，它不代表任何实际的文件，而只是用于构建 "px4_sitl_default" 目标的一个命令集合。
all: px4_sitl_default

# define a space character to be able to explicitly find it in strings
space := $(subst ,, )

#这段代码是一个 Makefile 文件中的一部分，用于定义一个名为 "make_list" 的函数。在 Makefile 中，函数是一种用于执行一系列命令的机制。在这个例子中，"make_list" 函数被用于查找名为 "check_${2}" 的 GitHub Actions 工作流。
#在 `make_list` 函数中，`$(shell ...)` 表示执行一个 shell 命令，并将其输出作为函数的返回值。`[ -f .github/workflows/compile_${1}.yml ]` 表示检查文件是否存在。如果文件存在，则使用 `cat` 命令读取文件内容，并使用 `sed` 命令将其中的字符串替换为 "check_${2}"。最后，使用 `grep` 命令查找包含 "check_${2}" 的行。
#总的来说，这段代码用于定义一个名为 "make_list" 的函数，用于查找名为 "check_${2}" 的 GitHub Actions 工作流。Makefile 是一种常见的构建工具，用于自动化构建过程。
define make_list
     $(shell [ -f .github/workflows/compile_${1}.yml ] && cat .github/workflows/compile_${1}.yml | sed -E 's|[[:space:]]+(.*),|check_\1|g' | grep check_${2})
endef

# Parsing
# --------------------------------------------------------------------
# assume 1st argument passed is the main target, the
# rest are arguments to pass to the makefile generated
# by cmake in the subdirectory
#`firstword` 函数被用于获取 Make 命令行中的第一个目标，并将其赋值给 `FIRST_ARG` 变量。`wordlist` 函数被用于获取 Make 命令行中的第二个及以后的目标，并将其赋值给 `ARGS` 变量。
FIRST_ARG := $(firstword $(MAKECMDGOALS))
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

# Get -j or --jobs argument as suggested in:
# https://stackoverflow.com/a/33616144/8548472
#在 Makefile 中，`MAKE_PID` 变量包含了当前 Make 进程的进程 ID。`ps` 命令用于列出当前系统中的进程列表，`sed` 命令用于从进程列表中查找包含当前 Make 进程 ID 的行，并提取出 `-j` 或 `--jobs` 参数后面的数字。
MAKE_PID := $(shell echo $$PPID)
j := $(shell ps T | sed -n 's|.*$(MAKE_PID).*$(MAKE).* \(-j\|--jobs\) *\([0-9][0-9]*\).*|\2|p')

# Default j for clang-tidy
#在 Makefile 中，`j_clang_tidy` 变量用于存储 Clang-Tidy 并行运行的线程数。如果用户在 Make 命令行中指定了 `-j` 参数，则使用用户指定的线程数。否则，使用默认值 4。
j_clang_tidy := $(or $(j),4)

#首先检查系统中是否安装了 Ninja 构建系统。
NINJA_BIN := ninja
ifndef NO_NINJA_BUILD
	NINJA_BUILD := $(shell $(NINJA_BIN) --version 2>/dev/null)

	ifndef NINJA_BUILD
		NINJA_BIN := ninja-build
		NINJA_BUILD := $(shell $(NINJA_BIN) --version 2>/dev/null)
	endif
endif
#如果安装了 Ninja，则将 `PX4_CMAKE_GENERATOR` 设置为 "Ninja"，将 `PX4_MAKE` 设置为 "ninja"，并将 `PX4_MAKE_ARGS` 设置为 "-v" 或 "-j$(j)"。如果用户在 Make 命令行中指定了 `-j` 参数，则使用用户指定的线程数。否则，使用默认值 4。
# 如果系统中没有安装 Ninja，则将 `PX4_CMAKE_GENERATOR` 设置为 "MSYS Makefiles" 或 "Unix Makefiles"，具体取决于操作系统类型。将 `PX4_MAKE` 设置为 "make"，将 `PX4_MAKE_ARGS` 设置为 "-j$(j) --no-print-directory"。如果用户在 Make 命令行中指定了 `-j` 参数，则使用用户指定的线程数。否则，使用默认值 4。
ifdef NINJA_BUILD
	PX4_CMAKE_GENERATOR := Ninja
	PX4_MAKE := $(NINJA_BIN)

	ifdef VERBOSE
		PX4_MAKE_ARGS := -v
	else
		PX4_MAKE_ARGS :=
	endif

	# Only override ninja default if -j is set.
	ifneq ($(j),)
		PX4_MAKE_ARGS := $(PX4_MAKE_ARGS) -j$(j)
	endif
else
	ifdef SYSTEMROOT
		# Windows
		PX4_CMAKE_GENERATOR := "MSYS\ Makefiles"
	else
		PX4_CMAKE_GENERATOR := "Unix\ Makefiles"
	endif

	# For non-ninja builds we default to -j4
	j := $(or $(j),4)
	PX4_MAKE = $(MAKE)
	PX4_MAKE_ARGS = -j$(j) --no-print-directory
endif

#这段代码用于获取当前 Makefile 文件所在的目录路径，并将其存储在 `SRC_DIR` 变量中。
SRC_DIR := $(shell dirname "$(realpath $(lastword $(MAKEFILE_LIST)))")

# check if replay env variable is set & set build dir accordingly
ifdef replay
	BUILD_DIR_SUFFIX := _replay
else
	BUILD_DIR_SUFFIX :=
endif

# 用于定义一个名为 `CMAKE_ARGS` 的变量,'?=` 表示如果 `CMAKE_ARGS` 变量未定义，则将其赋值为空字符串。如果 `CMAKE_ARGS` 变量已定义，则不会改变其值。
CMAKE_ARGS ?=

# additional config parameters passed to cmake
ifdef EXTERNAL_MODULES_LOCATION
	override CMAKE_ARGS += -DEXTERNAL_MODULES_LOCATION:STRING=$(EXTERNAL_MODULES_LOCATION)
endif

#`override` 关键字用于覆盖变量的默认值。这意味着如果用户定义了环境变量，则将覆盖默认的 CMake 命令行参数。
ifdef PX4_CMAKE_BUILD_TYPE
	override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=${PX4_CMAKE_BUILD_TYPE}
else

	# Address Sanitizer
	ifdef PX4_ASAN
		override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=AddressSanitizer
	endif

	# Memory Sanitizer
	ifdef PX4_MSAN
		override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=MemorySanitizer
	endif

	# Thread Sanitizer
	ifdef PX4_TSAN
		override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=ThreadSanitizer
	endif

	# Undefined Behavior Sanitizer
	ifdef PX4_UBSAN
		override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=UndefinedBehaviorSanitizer
	endif

	# Fuzz Testing
	ifdef PX4_FUZZ
		override CMAKE_ARGS += -DCMAKE_BUILD_TYPE=FuzzTesting
	endif

endif

# Pick up specific Python path if set
ifdef PYTHON_EXECUTABLE
	override CMAKE_ARGS += -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
endif

# Functions
# --------------------------------------------------------------------
# describe how to build a cmake config
define cmake-build
	$(eval override CMAKE_ARGS += -DCONFIG=$(1))
	@$(eval BUILD_DIR = "$(SRC_DIR)/build/$(1)")
	@# check if the desired cmake configuration matches the cache then CMAKE_CACHE_CHECK stays empty
	@$(call cmake-cache-check)
	@# make sure to start from scratch when switching from GNU Make to Ninja
	@if [ $(PX4_CMAKE_GENERATOR) = "Ninja" ] && [ -e $(BUILD_DIR)/Makefile ]; then rm -rf $(BUILD_DIR); fi
	@# make sure to start from scratch if ninja build file is missing
	@if [ $(PX4_CMAKE_GENERATOR) = "Ninja" ] && [ ! -f $(BUILD_DIR)/build.ninja ]; then rm -rf $(BUILD_DIR); fi
	@# only excplicitly configure the first build, if cache file already exists the makefile will rerun cmake automatically if necessary
	@if [ ! -e $(BUILD_DIR)/CMakeCache.txt ] || [ $(CMAKE_CACHE_CHECK) ]; then \
		mkdir -p $(BUILD_DIR) \
		&& cd $(BUILD_DIR) \
		&& cmake "$(SRC_DIR)" -G"$(PX4_CMAKE_GENERATOR)" $(CMAKE_ARGS) \
		|| (rm -rf $(BUILD_DIR)); \
	fi
	@# run the build for the specified target
	@cmake --build $(BUILD_DIR) -- $(PX4_MAKE_ARGS) $(ARGS)
endef

# check if the options we want to build with in CMAKE_ARGS match the ones which are already configured in the cache inside BUILD_DIR
define cmake-cache-check
	@# change to build folder which fails if it doesn't exist and CACHED_CMAKE_OPTIONS stays empty
	@# fetch all previously configured and cached options from the build folder and transform them into the OPTION=VALUE format without type (e.g. :BOOL)
	@$(eval CACHED_CMAKE_OPTIONS = $(shell cd $(BUILD_DIR) 2>/dev/null && cmake -L 2>/dev/null | sed -n 's|\([^[:blank:]]*\):[^[:blank:]]*\(=[^[:blank:]]*\)|\1\2|gp' ))
	@# transform the options in CMAKE_ARGS into the OPTION=VALUE format without -D
	@$(eval DESIRED_CMAKE_OPTIONS = $(shell echo $(CMAKE_ARGS) | sed -n 's|-D\([^[:blank:]]*=[^[:blank:]]*\)|\1|gp' ))
	@# find each currently desired option in the already cached ones making sure the complete configured string value is the same
	@$(eval VERIFIED_CMAKE_OPTIONS = $(foreach option,$(DESIRED_CMAKE_OPTIONS),$(strip $(findstring $(option)$(space),$(CACHED_CMAKE_OPTIONS)))))
	@# if the complete list of desired options is found in the list of verified options we don't need to reconfigure and CMAKE_CACHE_CHECK stays empty
	@$(eval CMAKE_CACHE_CHECK = $(if $(findstring $(DESIRED_CMAKE_OPTIONS),$(VERIFIED_CMAKE_OPTIONS)),,y))
endef

#于定义两个 ANSI 转义序列，分别用于输出蓝色文本和恢复默认文本颜色。在 Makefile 中，ANSI 转义序列用于控制终端输出的颜色和格式。
# 在这个例子中，`\033[0;94m` 表示输出蓝色文本的 ANSI 转义序列。`\033[m` 表示恢复默认文本颜色的 ANSI 转义序列
COLOR_BLUE = \033[0;94m
NO_COLOR   = \033[m

#`define` 关键字用于定义函数。`colorecho` 是函数的名称。`${1}` 表示函数的第一个参数。`+@echo -e` 表示执行一个带有转义序列的 echo 命令，用于输出带有蓝色文本颜色的信息。`${COLOR_BLUE}` 和 `${NO_COLOR}` 分别是用于输出蓝色文本和恢复默认文本颜色的 ANSI 转义序列。
define colorecho
+@echo -e '${COLOR_BLUE}${1} ${NO_COLOR}'
endef

# Get a list of all config targets boards/*/*.px4board
#用于查找所有的 PX4 飞控板配置文件，并将它们转换为 Makefile 目标。在 Makefile 中，目标是一种用于描述构建过程的机制。
#`find` 命令用于查找所有的 PX4 飞控板配置文件。`-maxdepth 3` 表示最大搜索深度为 3。`-mindepth 3` 表示最小搜索深度为 3。`-name '*.px4board'` 表示搜索扩展名为 .px4board 的文件。`-print` 表示输出文件名。
#`sed` 命令用于对文件名进行处理。`-e` 表示执行一个 sed 脚本。`s|boards\/||` 表示删除文件名中的 "boards/"。`s|\.px4board||` 表示删除文件名中的 ".px4board"。`s|\/|_|g` 表示将文件名中的 "/" 替换为 "_"。
#`sort` 命令用于对 Makefile 目标进行排序。
ALL_CONFIG_TARGETS := $(shell find boards -maxdepth 3 -mindepth 3 -name '*.px4board' -print | sed -e 's|boards\/||' | sed -e 's|\.px4board||' | sed -e 's|\/|_|g' | sort)

# ADD CONFIGS HERE
# --------------------------------------------------------------------
#  Do not put any spaces between function arguments.

# All targets.
$(ALL_CONFIG_TARGETS):
	@$(call cmake-build,$@$(BUILD_DIR_SUFFIX))

# Filter for only default targets to allow omiting the "_default" postfix
CONFIG_TARGETS_DEFAULT := $(patsubst %_default,%,$(filter %_default,$(ALL_CONFIG_TARGETS)))
$(CONFIG_TARGETS_DEFAULT):
	@$(call cmake-build,$@_default$(BUILD_DIR_SUFFIX))

all_config_targets: $(ALL_CONFIG_TARGETS)
all_default_targets: $(CONFIG_TARGETS_DEFAULT)

updateconfig:
	@./Tools/kconfig/updateconfig.py

# board reorganization deprecation warnings (2018-11-22)
define deprecation_warning
	$(warning $(1) has been deprecated and will be removed, please use $(2)!)
endef

# All targets with just dependencies but no recipe must either be marked as phony (or have the special @: as recipe).
#用于定义四个伪目标。在 Makefile 中，伪目标是一种用于描述构建过程的机制，它们不对应实际的文件。在这个例子中，`all`、`px4_sitl_default`、`all_config_targets` 和 `all_default_targets` 分别是四个伪目标的名称。
.PHONY: all px4_sitl_default all_config_targets all_default_targets

# Other targets
# --------------------------------------------------------------------

.PHONY: qgc_firmware px4fmu_firmware misc_qgc_extra_firmware

# QGroundControl flashable NuttX firmware
qgc_firmware: px4fmu_firmware misc_qgc_extra_firmware

# px4fmu NuttX firmware
px4fmu_firmware: \
	check_px4_io-v2_default \
	check_px4_fmu-v2_default \
	check_px4_fmu-v3_default \
	check_px4_fmu-v4_default \
	check_px4_fmu-v4pro_default \
	check_px4_fmu-v5_default \
	check_px4_fmu-v5x_default \
	sizes

misc_qgc_extra_firmware: \
	check_nxp_fmuk66-v3_default \
	check_nxp_fmurt1062-v1_default \
	check_mro_x21_default \
	check_bitcraze_crazyflie_default \
	check_bitcraze_crazyflie21_default \
	check_airmind_mindpx-v2_default \
	sizes

.PHONY: sizes check quick_check uorb_graphs

sizes:
	@-find build -name *.elf -type f | xargs size 2> /dev/null || :

# All default targets that don't require a special build environment
check: check_px4_sitl_default px4fmu_firmware misc_qgc_extra_firmware tests check_format

# quick_check builds a single nuttx and SITL target, runs testing, and checks the style
quick_check: check_px4_sitl_test check_px4_fmu-v5_default tests check_format

check_%:
	@echo
	$(call colorecho,'Building' $(subst check_,,$@))
	@$(MAKE) --no-print-directory $(subst check_,,$@)
	@echo

all_variants_%:
	@echo 'Building all $(subst all_variants_,,$@) variants:'  $(filter $(subst all_variants_,,$@)_%, $(ALL_CONFIG_TARGETS))
	@echo
	$(foreach a,$(filter $(subst all_variants_,,$@)_%, $(ALL_CONFIG_TARGETS)), $(call cmake-build,$(a)$(BUILD_DIR_SUFFIX)))

uorb_graphs:
	@./Tools/uorb_graph/create.py --src-path src --exclude-path src/examples --exclude-path src/lib/parameters --merge-depends --file Tools/uorb_graph/graph_full
	@./Tools/uorb_graph/create.py --src-path src --exclude-path src/examples --exclude-path src/lib/parameters --exclude-path src/modules/mavlink --merge-depends --file Tools/uorb_graph/graph_full_no_mavlink
	@$(MAKE) --no-print-directory px4_fmu-v2_default uorb_graph
	@$(MAKE) --no-print-directory px4_fmu-v4_default uorb_graph
	@$(MAKE) --no-print-directory px4_fmu-v5_default uorb_graph
	@$(MAKE) --no-print-directory px4_sitl_default uorb_graph

px4io_update:
	@$(MAKE) --no-print-directory px4_io-v2_default
	@$(MAKE) --no-print-directory cubepilot_io-v2_default
	# px4_io-v2_default
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/ark/fmu-v6x/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/holybro/durandal-v1/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/holybro/pix32v5/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/mro/x21/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/mro/x21-777/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v2/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v3/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v4pro/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v5/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v5x/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v6x/extras/px4_io-v2_default.bin
	cp build/px4_io-v2_default/px4_io-v2_default.bin boards/px4/fmu-v6c/extras/px4_io-v2_default.bin
	# cubepilot_io-v2_default
	cp build/cubepilot_io-v2_default/cubepilot_io-v2_default.bin boards/cubepilot/cubeorange/extras/cubepilot_io-v2_default.bin
	cp build/cubepilot_io-v2_default/cubepilot_io-v2_default.bin boards/cubepilot/cubeyellow/extras/cubepilot_io-v2_default.bin
	git status

bootloaders_update: ark_fmu-v6x_bootloader cuav_nora_bootloader cuav_x7pro_bootloader cubepilot_cubeorange_bootloader holybro_durandal-v1_bootloader holybro_kakuteh7_bootloader matek_h743_bootloader matek_h743-mini_bootloader matek_h743-slim_bootloader modalai_fc-v2_bootloader mro_ctrl-zero-classic_bootloader mro_ctrl-zero-h7_bootloader mro_ctrl-zero-h7-oem_bootloader mro_pixracerpro_bootloader px4_fmu-v6c_bootloader px4_fmu-v6u_bootloader px4_fmu-v6x_bootloader
	git status

.PHONY: coverity_scan

coverity_scan: px4_sitl_default

# Documentation
# --------------------------------------------------------------------
.PHONY: parameters_metadata airframe_metadata module_documentation extract_events px4_metadata doxygen

parameters_metadata:
	@$(MAKE) --no-print-directory px4_sitl_default metadata_parameters ver_gen

airframe_metadata:
	@$(MAKE) --no-print-directory px4_sitl_default metadata_airframes ver_gen

module_documentation:
	@$(MAKE) --no-print-directory px4_sitl_default metadata_module_documentation

extract_events:
	@$(MAKE) --no-print-directory px4_sitl_default metadata_extract_events ver_gen

px4_metadata: parameters_metadata airframe_metadata module_documentation extract_events

doxygen:
	@mkdir -p "$(SRC_DIR)"/build/doxygen
	@cd "$(SRC_DIR)"/build/doxygen && cmake "$(SRC_DIR)" $(CMAKE_ARGS) -G"$(PX4_CMAKE_GENERATOR)" -DCONFIG=px4_sitl_default -DBUILD_DOXYGEN=ON
	@$(PX4_MAKE) -C "$(SRC_DIR)"/build/doxygen
	@touch "$(SRC_DIR)"/build/doxygen/Documentation/.nojekyll

# Astyle
# --------------------------------------------------------------------
.PHONY: check_format format

check_format:
	$(call colorecho,'Checking formatting with astyle')
	@"$(SRC_DIR)"/Tools/astyle/check_code_style_all.sh
	@cd "$(SRC_DIR)" && git diff --check

format:
	$(call colorecho,'Formatting with astyle')
	@"$(SRC_DIR)"/Tools/astyle/check_code_style_all.sh --fix

# Testing
# --------------------------------------------------------------------
.PHONY: tests tests_coverage tests_mission tests_mission_coverage tests_offboard tests_avoidance
.PHONY: rostest python_coverage

tests:
	$(eval override CMAKE_ARGS += -DTESTFILTER=$(TESTFILTER))
	$(eval ARGS += test_results)
	$(eval ASAN_OPTIONS += color=always:check_initialization_order=1:detect_stack_use_after_return=1)
	$(eval UBSAN_OPTIONS += color=always)
	$(call cmake-build,px4_sitl_test)

tests_coverage:
	@$(MAKE) clean
	@$(MAKE) --no-print-directory tests PX4_CMAKE_BUILD_TYPE=Coverage
	@mkdir -p coverage
	@lcov --directory build/px4_sitl_test --base-directory build/px4_sitl_test --gcov-tool gcov --capture -o coverage/lcov.info


rostest: px4_sitl_default
	@$(MAKE) --no-print-directory px4_sitl_default sitl_gazebo-classic

tests_integration: px4_sitl_default
	@$(MAKE) --no-print-directory px4_sitl_default sitl_gazebo-classic
	@$(MAKE) --no-print-directory px4_sitl_default mavsdk_tests
	@"$(SRC_DIR)"/test/mavsdk_tests/mavsdk_test_runner.py --speed-factor 20 test/mavsdk_tests/configs/sitl.json

tests_integration_coverage:
	@$(MAKE) clean
	@$(MAKE) --no-print-directory px4_sitl_default PX4_CMAKE_BUILD_TYPE=Coverage
	@$(MAKE) --no-print-directory px4_sitl_default sitl_gazebo-classic
	@$(MAKE) --no-print-directory px4_sitl_default mavsdk_tests
	@"$(SRC_DIR)"/test/mavsdk_tests/mavsdk_test_runner.py --speed-factor 20 test/mavsdk_tests/configs/sitl.json
	@mkdir -p coverage
	@lcov --directory build/px4_sitl_default --base-directory build/px4_sitl_default --gcov-tool gcov --capture -o coverage/lcov.info

tests_mission: rostest
	@"$(SRC_DIR)"/test/rostest_px4_run.sh mavros_posix_tests_missions.test

rostest_run: px4_sitl_default
	@$(MAKE) --no-print-directory px4_sitl_default sitl_gazebo-classic
	@"$(SRC_DIR)"/test/rostest_px4_run.sh $(TEST_FILE) mission:=$(TEST_MISSION) vehicle:=$(TEST_VEHICLE)

tests_mission_coverage:
	@$(MAKE) clean
	@$(MAKE) --no-print-directory px4_sitl_default PX4_CMAKE_BUILD_TYPE=Coverage
	@$(MAKE) --no-print-directory px4_sitl_default sitl_gazebo-classic PX4_CMAKE_BUILD_TYPE=Coverage
	@"$(SRC_DIR)"/test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=VTOL_mission_1 vehicle:=standard_vtol
	@$(MAKE) --no-print-directory px4_sitl_default generate_coverage

tests_offboard: rostest
	@"$(SRC_DIR)"/test/rostest_px4_run.sh mavros_posix_tests_offboard_attctl.test
	@"$(SRC_DIR)"/test/rostest_px4_run.sh mavros_posix_tests_offboard_posctl.test
	@"$(SRC_DIR)"/test/rostest_px4_run.sh mavros_posix_tests_offboard_rpyrt_ctl.test

tests_avoidance: rostest
	@"$(SRC_DIR)"/test/rostest_avoidance_run.sh mavros_posix_test_avoidance.test
	@"$(SRC_DIR)"/test/rostest_avoidance_run.sh mavros_posix_test_safe_landing.test

python_coverage:
	@mkdir -p "$(SRC_DIR)"/build/python_coverage
	@cd "$(SRC_DIR)"/build/python_coverage && cmake "$(SRC_DIR)" $(CMAKE_ARGS) -G"$(PX4_CMAKE_GENERATOR)" -DCONFIG=px4_sitl_default -DPYTHON_COVERAGE=ON
	@$(PX4_MAKE) -C "$(SRC_DIR)"/build/python_coverage
	@$(PX4_MAKE) -C "$(SRC_DIR)"/build/python_coverage metadata_airframes
	@$(PX4_MAKE) -C "$(SRC_DIR)"/build/python_coverage metadata_parameters
	#@$(PX4_MAKE) -C "$(SRC_DIR)"/build/python_coverage module_documentation # TODO: fix within coverage.py
	@coverage combine `find . -name .coverage\*`
	@coverage report -m


# static analyzers (scan-build, clang-tidy, cppcheck)
# --------------------------------------------------------------------
.PHONY: scan-build px4_sitl_default-clang clang-tidy clang-tidy-fix clang-tidy-quiet
.PHONY: cppcheck shellcheck_all validate_module_configs

scan-build:
	@export CCC_CC=clang
	@export CCC_CXX=clang++
	@rm -rf "$(SRC_DIR)"/build/px4_sitl_default-scan-build
	@rm -rf "$(SRC_DIR)"/build/scan-build/report_latest
	@mkdir -p "$(SRC_DIR)"/build/px4_sitl_default-scan-build
	@cd "$(SRC_DIR)"/build/px4_sitl_default-scan-build && scan-build cmake "$(SRC_DIR)" -GNinja -DCONFIG=px4_sitl_default
	@scan-build -o "$(SRC_DIR)"/build/scan-build cmake --build "$(SRC_DIR)"/build/px4_sitl_default-scan-build
	@find "$(SRC_DIR)"/build/scan-build -maxdepth 1 -mindepth 1 -type d -exec cp -r "{}" "$(SRC_DIR)"/build/scan-build/report_latest \;

px4_sitl_default-clang:
	@mkdir -p "$(SRC_DIR)"/build/px4_sitl_default-clang
	@cd "$(SRC_DIR)"/build/px4_sitl_default-clang && cmake "$(SRC_DIR)" $(CMAKE_ARGS) -G"$(PX4_CMAKE_GENERATOR)" -DCONFIG=px4_sitl_default -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
	@$(PX4_MAKE) -C "$(SRC_DIR)"/build/px4_sitl_default-clang

clang-tidy: px4_sitl_default-clang
	@cd "$(SRC_DIR)"/build/px4_sitl_default-clang && "$(SRC_DIR)"/Tools/run-clang-tidy.py -header-filter=".*\.hpp" -j$(j_clang_tidy) -p .

# to automatically fix a single check at a time, eg modernize-redundant-void-arg
#  % run-clang-tidy-4.0.py -fix -j4 -checks=-\*,modernize-redundant-void-arg -p .
clang-tidy-fix: px4_sitl_default-clang
	@cd "$(SRC_DIR)"/build/px4_sitl_default-clang && "$(SRC_DIR)"/Tools/run-clang-tidy.py -header-filter=".*\.hpp" -j$(j_clang_tidy) -fix -p .

# modified version of run-clang-tidy.py to return error codes and only output relevant results
clang-tidy-quiet: px4_sitl_default-clang
	@cd "$(SRC_DIR)"/build/px4_sitl_default-clang && "$(SRC_DIR)"/Tools/run-clang-tidy.py -header-filter=".*\.hpp" -j$(j_clang_tidy) -p .

# TODO: Fix cppcheck errors then try --enable=warning,performance,portability,style,unusedFunction or --enable=all
cppcheck: px4_sitl_default
	@mkdir -p "$(SRC_DIR)"/build/cppcheck
	@cppcheck -i"$(SRC_DIR)"/src/examples --enable=performance --std=c++14 --std=c99 --std=posix --project="$(SRC_DIR)"/build/px4_sitl_default/compile_commands.json --xml-version=2 2> "$(SRC_DIR)"/build/cppcheck/cppcheck-result.xml > /dev/null
	@cppcheck-htmlreport --source-encoding=ascii --file="$(SRC_DIR)"/build/cppcheck/cppcheck-result.xml --report-dir="$(SRC_DIR)"/build/cppcheck --source-dir="$(SRC_DIR)"/src/

shellcheck_all:
	@"$(SRC_DIR)"/Tools/run-shellcheck.sh "$(SRC_DIR)"/ROMFS/px4fmu_common/
	@make px4_fmu-v5_default shellcheck

validate_module_configs:
	@find "$(SRC_DIR)"/src/modules "$(SRC_DIR)"/src/drivers "$(SRC_DIR)"/src/lib -name *.yaml -type f \
	-not -path "$(SRC_DIR)/src/lib/mixer_module/*" \
	-not -path "$(SRC_DIR)/src/modules/uxrce_dds_client/dds_topics.yaml" \
	-not -path "$(SRC_DIR)/src/modules/zenoh/zenoh-pico/*" \
	-not -path "$(SRC_DIR)/src/lib/events/libevents/*" \
	-not -path "$(SRC_DIR)/src/lib/cdrstream/*" \
	-not -path "$(SRC_DIR)/src/lib/crypto/libtommath/*" -print0 | \
	xargs -0 "$(SRC_DIR)"/Tools/validate_yaml.py --schema-file "$(SRC_DIR)"/validation/module_schema.yaml

# Cleanup
# --------------------------------------------------------------------
.PHONY: clean submodulesclean submodulesupdate distclean

clean:
	@[ ! -d "$(SRC_DIR)/build" ] || find "$(SRC_DIR)/build" -mindepth 1 -maxdepth 1 -type d -exec sh -c "echo {}; cmake --build {} -- clean || rm -rf {}" \; # use generated build system to clean, wipe build directory if it fails
	@git submodule foreach git clean -dX --force # some submodules generate build artifacts in source

submodulesclean:
	@git submodule foreach --quiet --recursive git clean -ff -x -d
	@git submodule update --quiet --init --recursive --force || true
	@git submodule sync --recursive
	@git submodule update --init --recursive --force --jobs 4

submodulesupdate:
	@git submodule update --quiet --init --recursive --jobs 4 || true
	@git submodule sync --recursive
	@git submodule update --init --recursive --jobs 4
	@git fetch --all --tags --recurse-submodules=yes --jobs=4

distclean:
	@git submodule deinit --force $(SRC_DIR)
	@rm -rf "$(SRC_DIR)/build"
	@git clean --force -X "$(SRC_DIR)/msg/" "$(SRC_DIR)/platforms/" "$(SRC_DIR)/posix-configs/" "$(SRC_DIR)/ROMFS/" "$(SRC_DIR)/src/" "$(SRC_DIR)/test/" "$(SRC_DIR)/Tools/"

# Help / Error / Misc
# --------------------------------------------------------------------

# All other targets are handled by PX4_MAKE. Add a rule here to avoid printing an error.
%:
	$(if $(filter $(FIRST_ARG),$@), \
		$(error "Make target $@ not found. It either does not exist or $@ cannot be the first argument. Use '$(MAKE) help|list_config_targets' to get a list of all possible [configuration] targets."),@#)

# Print a list of non-config targets (based on http://stackoverflow.com/a/26339924/1487069)
help:
	@echo "Usage: $(MAKE) <target>"
	@echo "Where <target> is one of:"
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | \
		awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^($(subst $(space),|,$(ALL_CONFIG_TARGETS)))$$' -e '_default$$' -e '^(Makefile)'
	@echo
	@echo "Or, $(MAKE) <config_target> [<make_target(s)>]"
	@echo "Use '$(MAKE) list_config_targets' for a list of configuration targets."

# Print a list of all config targets.
list_config_targets:
	@for targ in $(patsubst %_default,%[_default],$(ALL_CONFIG_TARGETS)); do echo $$targ; done

check_nuttx : $(call make_list,nuttx) \
	sizes

check_linux : $(call make_list,linux) \
	sizes

check_px4: $(call make_list,nuttx,"px4") \
	sizes

check_nxp: $(call make_list,nuttx,"nxp") \
	sizes

# helpers for running olddefconfig (nuttx) and px4_savedefconfig on all boards
.PHONY: all_oldconfig all_px4_savedefconfig
all_oldconfig:
	@for targ in $(ALL_CONFIG_TARGETS); do $(MAKE) $$targ oldconfig; done

all_px4_savedefconfig:
	@for targ in $(ALL_CONFIG_TARGETS); do $(MAKE) $$targ px4_savedefconfig; done

.PHONY: failsafe_web run_failsafe_web_server
failsafe_web:
	@if ! command -v emcc; then echo -e "Install emscripten first: https://emscripten.org/docs/getting_started/downloads.html\nAnd source the env: source <path>/emsdk_env.sh"; exit 1; fi
	@$(MAKE) --no-print-directory px4_sitl_default failsafe_test parameters_xml \
		PX4_CMAKE_BUILD_TYPE=Release BUILD_DIR_SUFFIX=_failsafe_web \
		CMAKE_ARGS="-DCMAKE_CXX_COMPILER=em++ -DCMAKE_C_COMPILER=emcc"
run_failsafe_web_server: failsafe_web
	@cd build/px4_sitl_default_failsafe_web && \
		python3 -m http.server
