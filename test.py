from paste import httpserver
import howmuchsnowcgi
httpserver.serve(howmuchsnowcgi.app, host='127.0.0.1', port='8080')
