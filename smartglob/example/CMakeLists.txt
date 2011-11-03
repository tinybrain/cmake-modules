# SmartGlob Example
#
# Copyright (C) 2011 by a llama.  All rights reserved.
#
# This code is licensed under the MIT License.
# Refer to SmartGlob.cmake for the full license text.

cmake_minimum_required(VERSION 2.8)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/../modules)

include(SmartGlob)

project(Hello)

smartglob(GLOB_ME_SRCS src/glob-me)

add_executable(hello
	${GLOB_ME_SRCS}
	src/main.c
	)

smartglob_add_dependencies(hello)
