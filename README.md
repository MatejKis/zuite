An app for easier testing of zig projects. Provides simpler and less comprehensive output of zig tests.

**Note:** This is W.I.P. it is tested only minimally and only on Endeavour OS. Many features are missing 
and any suggestions and critique would be much appreciated.

---

## Installation

---
## Usage
Run command ``zuite`` in a directory you want to test. Tests will be run for every .zig file prefixed `t_` or `test_`.

---
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