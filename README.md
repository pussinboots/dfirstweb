dfirstweb
=========

- Travis Ci https://travis-ci.org/pussinboots/dfirstweb
- Heroku buildpack D https://github.com/pussinboots/heroku-buildpack-d


My first steps with the D programming language. I will try to build a simple json rest service
, that i already have programmed with scala, with the D language.

First step build D with travis ci.
<b>Done</b> link to travis ci build https://travis-ci.org/pussinboots/dfirstweb
The build is now also green and use
    dub build
as defsult build command.

Second step run D with the heroku plattform.

first set custom buildpack for D ( https://github.com/pussinboots/heroku-buildpack-d )

    heroku config:set BUILDPACK_URL=https://github.com/pussinboots/heroku-buildpack-d

If you want to build a vibe.d based application than see the file (dub-prebuild)
that added two binaries dependencies to the heroku vm (libevent, libev) they
are needed by vibe.d.

For runtime add the pkg config folder to the PKG_CONFIG_PATH environment variable so that 
all libaries they was build during the dub prebuild (libevent and libev) needed for the
vibe.d framework are also accessibile during runtime. The command below add the pkg config folder
from /app/opt/lib/pkgconfig to the PKG_CONFIG_PATH environment variable. The second environment
variable LD_LIBRARY_PATH is also need to find the dependent library at runtime.

    heroku config:add PKG_CONFIG_PATH=/app/opt/lib/pkgconfig
    heroku config:add LD_LIBRARY_PATH=/app/opt/lib
