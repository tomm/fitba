default:
	./node_modules/.bin/elm-make client/*.elm --output public/main.js

install:
	bundle install
	npm install
