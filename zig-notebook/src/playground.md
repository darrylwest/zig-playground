# Zig Playground

We use the playground as a starting point for learning **zig**.  Zig examples demonstate control flows, language basics, types, etc.  There is also a build configuration created to support single-file scripts.

## Utilities

The **util** folder contains simple single-file demonstraction scripts.  It has a build script, **build.zig**, tuned for single-file compilation.  Scripts include...

- Basic "Hello World" program (`hello.zig`)
- String literals and Unicode handling (`string_literals.zig`)
- Value types, optionals, and error unions (`values.zig`)

### Build Configuration

The build file is **build.zig** and contains a list of files to be compiled.  Output is written to **zig-out/bin**.

1. Automatically discovers all .zig files in the current directory using filesystem iteration
2. Excludes build.zig from compilation
3. Compiles each discovered file into separate executables in zig-out/bin/

To extend, simply add a new **zig** file and run **zig build** to compile. *No build.zip changes are required.*


###### dpw | 2025.09.22
