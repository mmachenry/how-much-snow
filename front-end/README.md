how-much-snow/web-app
===========

This is the web front end to how-much-snow. It is a single-page application that makes HTTP requests to the REST API backend.

Installation
---

    elm-make --output ../docs/index.html src/Main.elm
    aws s3 sync ../docs/ s3://mmachenry-how-much-snow
