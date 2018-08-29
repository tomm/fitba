default:
	bundle install
	npm install
	$(MAKE) quick

quick:
	./node_modules/.bin/elm-package install
	./node_modules/.bin/elm-make client/*.elm 3rdparty/*.elm --output public/main.js --warn
