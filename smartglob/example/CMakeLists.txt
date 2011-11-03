# SmartGlob Example
#
# Copyright (C) 2011 by a llama.  All rights reserved.
#
# This code is licensed under the MIT License.
# Refer to SmartGlob.cmake for the full license text.

cmake_minimum_required(VERSION 2.8)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ../modules)

include(SmartGlob)

project(Hello)

set(CUSTOM_EXTENSIONS .h .c)

smartglob(GLOB_ME_SRCS src/glob-me)
#smartglob(GLOB_ME_SRCS src/glob-me EXTENSIONS ${CUSTOM_EXTENSIONS})

add_executable(hello
	${GLOB_ME_SRCS}
	src/main.c
	)

smartglob_add_dependencies(hello)
