# CmdMode
PowerShell module allowing you to effectively run CMD with tab-completion, persistent history, syntax highlighting, superior line editing capabilities, and other PowerShell (and PSReadLine) features.

Allows for switching back and forth between CMD and PowerShell in the same session, sharing the same enivronment.

## Getting Started
### Prequisites
[PSReadLine](https://github.com/lzybkr/PSReadLine), which is installed by default on Windows 10, is required.  If you are not on Windows 10, and install CmdMode via the PowerShell Gallery, it will be automatically installed also.  Otherwise, you will need to install it prior to using CmdMode.

### Installation
Install via the [PowerShell Gallery](https://www.powershellgallery.com) like so:
```
Install-Module CmdMode
Import-Module CmdMode
```

Alternatively, clone this repo, and import:
```
git clone https://github.com/jimmehc/CmdMode.git
Import-Module CmdMode\CmdMode.psm1
```

### How to Use
Once the module is imported, run `cmdmode` (or `Enter-CmdMode`) to enter CMD mode.  

In CMD mode, all commands are run as if you were running cmd.exe natively, but the interactive shell enhancements provided by PowerShell/PSReadLine, as well as any customization, are retained.  

This means you'll have enhanced tab-completion (bash-style, if enabled in PSReadLine), persistent history, superior line editing capabilities (cut/copy/paste/select etc.), interactive history searching via Ctrl-R, any custom PSReadLine key handlers, and many other interactive shell features present in PowerShell.

To switch back to PowerShell, run `psmode`.  You will notice that any changes you made to environment variables while in CMD mode are present in PowerShell.

## Caveats
I've been using this myself without many issues for a while, but I haven't extensively tested it.  I'm sure there are ways to break it, and that not everything works properly.  Please open a bug if you encounter any problems.
