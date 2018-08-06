default:
	bundle install
	npm install
	./node_modules/.bin/elm-package install
	./node_modules/.bin/elm-make client/*.elm --output public/main.js
