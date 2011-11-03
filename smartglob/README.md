SmartGlob.cmake
===============

The built in functions for building source file lists using globs are convenient, however frowned upon because any changes to the globbed directories are not detected during CMake's check phase.

SmartGlob duplicitously attempts to both eat and have cake by maintaining a cache of the result of each glob.  It will then diff the expected glob result with the current contents and force a regeneration if there are any changes.

### An Example

Import the module.

```cmake
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/../modules)

include(SmartGlob)
```

Glob a directory.

```cmake
# use the default filter
smartglob(GLOB_ME_SRCS src/glob-me)
```

or maybe...

```cmake
# increasificate some specificacity
smartglob(GLOB_ME_SRCS src/glob-me REGEX "my-special-[0-9A-Za-z]*\.[h|c]$")
```

Add the result to a target.

```cmake
add_executable(hello
	${GLOB_ME_SRCS}
	src/main.c
	)
```

Finally, add any generated preflight dependancies to the target.

```cmake
smartglob_add_dependencies(hello)
```

### Building It

Here's the included example in operation.

First, get it and make a shadow build directory.

```
$ git clone git@github.com:llamatron/cmake-modules.git
$ mkdir cmake-modules/smartglob/build && cd $_
$ cmake ../example/
```

The globbed directory `src/glob-me` produces the preflight target `smartglob-src-glob-me`.

```
$ make
Scanning dependencies of target smartglob-src-glob-me
[  0%] Built target smartglob-src-glob-me
Scanning dependencies of target hello
[ 50%] Building C object CMakeFiles/hello.dir/src/glob-me/thing.c.o
[100%] Building C object CMakeFiles/hello.dir/src/main.c.o
Linking C executable hello
[100%] Built target hello
```

Now add a new source file and try to build.

```
$ touch ../example/src/glob-me/new_thing.c
$ make
CMake Warning at /scratch/cmake-modules/smartglob/modules/SmartGlob.cmake:166 (message):
  *** SmartGlob Warning ***
Call Stack (most recent call first):
  /scratch/cmake-modules/smartglob/modules/SmartGlob.cmake:187 (smartglob_preflight)

SmartGlob detected a glob change!!  Rebuild to update projects and caches.
  Added: /scratch/cmake-modules/smartglob/example/src/glob-me/new_thing.c


[  0%] Built target smartglob-src-glob-me
[100%] Built target hello
```

Try not to over-exert yourself.

```
$ make
-- Configuring done
-- Generating done
-- Build files have been written to: /scratch/cmake-modules/smartglob/build
[  0%] Built target smartglob-src-glob-me
Scanning dependencies of target hello
[ 33%] Building C object CMakeFiles/hello.dir/src/glob-me/new_thing.c.o
Linking C executable hello
[100%] Built target hello
```
Easy peasy, lemon squeazy!

### Functions

**smartglob**

```cmake
smartglob(<out filelist var> <glob path> [ EXTENSIONS | REGEX  <filter> ])
```

Glob the files in `<glob path>` and put the results in `<out filelist var>`.  

A glob `<filter>` may be specified with :

```
EXTENSIONS 	Space or comma delimited list of extensions.
REGEX 		Regular Expression.
```
	
Otherwise the default filter is used :

```
".h .hpp .hxx .c .cpp .cxx .m .mm"
```

* Produces a glob definition file in `${CMAKE_BINARY_DIR}/smartglob/`.

* Creates a preflight target and appends it to `SMARTGLOB_PREFLIGHTS` in the parent scope.


**smartglob_format_path**

```cmake
smartglob_format_prefix(<out prefix var> <path> [TARGET])
```

Generate a smartglob prefix or target name from `<path>`, and assigns it to `<out prefix var>`.

```
TARGET 	Prepends 'smartglob-' to the prefix to produce a target name.
```	

If the globbed directory is e.g. `SRC/Some Functions/` the prefix will be formatted as `src-some_functions`.

**smartglob_add_dependencies**

```cmake
smartglob_add_dependencies(<target>)
```

Sets any preflight targets listed in `SMARTGLOB_PREFLIGHTS` as dependant targets of `<target>`.  

The list of preflight targets is cleared for the next target.

If a glob is to be used in more than one target, its preflight target will need to be added manually, e.g.  :

```cmake
add_dependencies(first-executable smartglob-src-some_functions)
add_dependencies(second-executable smartglob-src-some_functions)
```
