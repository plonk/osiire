all:
	ruby ../mogeRPG/png2sixel.rb tileset16.png  > tileset16.six
	drcssixel-test -c @ -q -d 8x16 ./tileset16.six > font.txt
	cat font.txt
	ruby ../mogeRPG/png2sixel.rb tileset16-2.png  > tileset16-2.six
	drcssixel-test -c A -q -d 8x16 ./tileset16-2.six > font-2.txt
	cat font-2.txt