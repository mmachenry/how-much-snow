.PHONY: build run deploy clean

run:
	parcel src/index.html

build:
	parcel build src/index.html

upload:
	aws s3 sync dist/ s3://mmachenry-how-much-snow

invalidate:
	aws cloudfront create-invalidation \
		--distribution-id E1M1QT3J98ATWO \
		--paths "/*"

deploy: build upload invalidate

clean:
	rm -r dist/
	rm -r elm-stuff/
	rm -r node_modules/
	rm -r .cache
