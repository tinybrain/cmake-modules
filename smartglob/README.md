SmartGlob.cmake
===============

The built in functions for building source file lists using globs are convenient, however frowned upon because any changes to the globbed directories are not detected during CMake's check phase.

SmartGlob tries to simultaneously have and eat cake, by caching the result of each glob and using it to diff the contents of the directory.

### Example

Get the example and generate a build.

```bash
$ git clone git@github.com:llamatron/cmake-modules.git
$ mkdir cmake-modules/smartglob/build && cd $_
$ cmake ../example/
```

The globbed directory `src/glob-me` produces the preflight target `smartglob-src-glob-me`.

```bash
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

```bash
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

```bash
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

**smartglob** : Glob the files in a given path.

```cmake
smartglob(<out filelist var> <glob path> [ EXTENSIONS | REGEX  <filter> ])
```

```
	EXTENSIONS	Indicates <filter> is a space delimited list of extensions.
	REGEX		Indicates <filter> is a literal regular expression.
```
		

Globs the files in `<glob path>` and puts the results in `<out filelist var>`, filtered either with the default extension list or a user defined list.

The default extensions filter includes the most common native source file types and is defined as :

```
".h .hpp .hxx .c .cpp .cxx .m .mm"
```

Each glob generates a glob definition file in `${CMAKE_BINARY_DIR}/smartglob/` and a custom preflight target which must be set as a dependancy of the current target. The dependant target names are appended to `SMARTGLOB_PREFLIGHTS` in the parent scope.

**smartglob_format_path** : Generate a smartglob prefix or target from a path.

```cmake
smartglob_format_prefix(<out result var> <path> [TARGET])
```

```
	TARGET 	Prepends 'smartglob-' to the prefix to produce a target name.
```	

If the globbed directory is e.g. `SRC/Some Functions/` the prefix will be formatted as `src-some_functions`.

**smartglob_add_dependencies** : Add previously generated smart glob targets to the specified target.

```cmake
smartglob_add_dependencies(<target>)
```

Sets any previously defined preflight targets listed in `SMARTGLOB_PREFLIGHTS` as dependant targets of `<target>`.  The list of preflight targets is then cleared for the next target.

If a glob is to be used in more than one target, its preflight target will need to be added manually, e.g.

```cmake
add_dependencies(my-library smartglob-src-myfiles-stuff)
add_dependencies(my-executable smartglob-src-myfiles-stuff)
```
