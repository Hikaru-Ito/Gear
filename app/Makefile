apps: data.json images/loading.gif javascripts/gear.js js
	/bin/rm -r -f build
	nwbuild .
dmg: apps
	hdiutil create -srcfolder build/Gear/osx64/Gear.app -volname Gear Gear.dmg
zip: apps
	zip Gear.zip build/Gear/win64/*

data.json: ../data/data.json
	cp ../data/data.json .

../data/data.json:
	cd ../data; make

javascripts/gear.js: ../javascripts/gear.coffee
	-mkdir javascripts
	cp ../javascripts/gear.coffee javascripts
	coffee -c -b javascripts/gear.coffee

js:
	-mkdir javascripts
	cp ../javascripts/*.js javascripts

clean:
	/bin/rm -r -f build Gear.dmg Gear.zip javascripts data.json

#images/loading.gif: ../images/loading.gif
#	-mkdir images
#	cp ../images/loading.gif images
#
#app: data.json javascripts/gear.js images/loading.gif
#	zip app.nw \
#		package.json \
#		index.html \
#		stylesheets/gear.css \
#		javascripts/jquery.js \
#		javascripts/jquery.mousewheel.js \
#		javascripts/gear.js \
#		javascripts/linda.js \
#		javascripts/socket.io.js \
#		data.json \
#		images/loading.gif
#mac: app
#	/bin/rm -f Gear.dmg
#	cp app.nw Gear.app/Contents/Resources
#dmg: mac
#	hdiutil create -srcfolder Gear.app -volname Gear Gear.dmg
#
#windows: app
#	/bin/rm -f Gear.zip
#	cat Gear/nw.exe app.nw > Gear/Gear.exe
#zip: windows
#	zip Gear.zip Gear/*
#
#upload: dmg zip
#	scp Gear.zip pitecan.com:/www/www.pitecan.com/tmp
#	scp Gear.dmg pitecan.com:/www/www.pitecan.com/tmp
#
#demo: apps
#	open Gear.app
#	cd ../arduino; make

