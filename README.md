An app for easier testing of zig projects. Provides simpler and less comprehensive output of zig tests.

**Note:** This is W.I.P. it is tested only minimally and only on Endeavour OS. Many features are missing 
and any suggestions and critique would be much appreciated.


## Installation

### Unix systems
Run the following command:

`curl -fsSL https://raw.githubusercontent.com/MatejKis/zuite/main/install.sh | bash`

Otherwise you can clone the repository and run `install.sh` file

### Windows
1. Download the correct installation of the desired version under releases
2. Unzip the file
3. Add the file to your $PATH:

For system-wide access:
`[Environment]::SetEnvironmentVariable(
   "Path",
   [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\your-path\zuite-your-version-windows-x86_64",
   "Machine"
)`

For user access:
`[Environment]::SetEnvironmentVariable(
   "Path",
   [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\your-path\zuite-your-version-windows-x86_64",
   "User"
)`



### Manual installation
1. Clone this repository to your device
2. Move to the directory
3. Run `zig build install --prefix /usr/local`

*Note: The part `/usr/local` determines the install location of the app. It therefore can be changed to whatever suits your needs. For example, if you do not have superuser privilages, you can instead use a location which wouldn't require them.*

## Usage
Run command ``zuite`` in a directory you want to test. Tests will be run for every .zig file prefixed `t_` or `test_`.

## Flags
### `-p` or `--path`
Specifies the directory or file which to test.
    
    zuite -p /src
    zuite -p /src/t_main.zig
- - -
### `-f` or `--filter`
Allows for filtering the files to be tested. Only the files containing the filtering string will be tested. 

    zuite -f colors
- - -
### `-w` or `--watch`
Starts the watch mode. The tests are run every 5 seconds.
    
    zuite --watch
- - -
