how-much-snow/front-end
===========

This is the web front end to how-much-snow. It is a single-page application that makes HTTP requests to the REST API backend.

Installation
---

    elm-make --output html/main.js src/Main.elm
    aws s3 sync html/ s3://mmachenry-how-much-snow
