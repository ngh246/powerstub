# PowerStub
PowerStub is a slightly more powerful PowerShell stub for Wine that implements the bare minimum Start-Process functionality to make RSI Launcher able to make & verify installation directories.

## How do I install?
First, download a [release tarball](https://github.com/ngh246/powerstub/releases) or build it yourself.

Run the install.sh script to automagically install, if you're feeling lucky.
Remember to set the `WINE` and `WINEPREFIX` environment variables if you're using a non-default Wine or prefix. ("Open Bash terminal" in Lutris does this for you)

If you prefer doing things manually, copy...
- `x86/powershell.exe` to `C:\windows\syswow64\WindowsPowerShell/v1.0/powershell.exe`
- `x86_64/powershell.exe` to `C:\windows\system32\WindowsPowerShell/v1.0/powershell.exe`

... in to your Wine prefix. Then in the winecfg libraries tab override `powershell.exe` to native.

## How do I build?
With the [Zig](https://ziglang.org/) build system. You'll want a recent master branch build of Zig.

`zig build release` builds 32-bit and 64-bit Windows binaries, and copies the install script to the install prefix (default: `zig-out`). This is probably what you want.

You can run `zig build` to build a rather useless native binary.

