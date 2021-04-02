# Package

version       = "0.1.0"
author        = "Jonathan Bernard"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src/nim"
bin           = @["jira_analysis"]


# Dependencies

requires @["nim >= 1.4.0", "docopt", "uuids", "timeutils", "fiber_orm >= 0.3.1"]
#requires "https://git.jdb-software.com/jdb-software/fiber-orm-nim.git"
requires "https://github.com/andreaferretti/csvtools.git"
