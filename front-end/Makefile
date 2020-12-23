.PHONY: build run deploy clean

run:
	parcel src/index.html

build:
	parcel build src/index.html

deploy: build
	aws s3 sync dist/ s3://mmachenry-how-much-snow

clean:
	rm -r dist/
	rm -r elm-stuff/
	rm -r node_modules/
	rm -r .cache
