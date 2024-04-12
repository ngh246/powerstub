# PowerStub
PowerStub is a slightly more powerful PowerShell stub for Wine that implements the bare minimum Start-Process functionality to make RSI Launcher able to make & verify installation directories.

## How do I install?
You can use the install.sh script in the release tarball if you're feeling lucky.

To manually install, copy...
- `x86/powershell.exe` to `C:\windows\syswow64\WindowsPowerShell/v1.0/powershell.exe`
- `x86_64/powershell.exe` to `C:\windows\system32\WindowsPowerShell/v1.0/powershell.exe`

... in to your Wine prefix. Then in the winecfg libraries tab override `powershell.exe` to native.

## How do I build?
With the [Zig](https://ziglang.org/) build system. You'll want a recent master branch build of Zig. You can run `zig build` to build a rather useless native binary. `zig build release` to build 32-bit and 64-bit Windows binaries.

