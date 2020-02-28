default:
	bundle install
	npm install
	$(MAKE) quick

quick:
	#npx elm install
	npx elm make client/Main.elm --output public/main.js
