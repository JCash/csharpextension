
# Notes

* `-flto`` seems to remove something vital and the exe crashes

    - Can we use e.g. "__attribute__((used))" or similar?
    - Is there a linker flag to keep symbols? e.g. "ExportsFile" ?

# Questions

* Is it possible to statically link with the dynamic libraries?

    - Yes. Instead of linking as "-lSystem.Native" add them directly as a source file

* Can we avoid using the reflection layer, to save 40% size?

    - Currently using TryGetFunctionPointer fails

Sizes:

4294856 test

144672 libSystem.Native.dylib
156096 libSystem.Globalization.Native.dylib
888640 libSystem.IO.Compression.Native.dylib



Notes for configurability:

"If you set InvariantGlobalization in your csproj to true, then it’ll skip using ICU."

