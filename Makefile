all:
	ruby ../mogeRPG/png2sixel.rb tileset16.png  > tileset16.six
	drcssixel-test -c @ -q -d 8x16 ./tileset16.six > font.txt
	cat font.txt
	ruby ../mogeRPG/png2sixel.rb tileset16-2.png  > tileset16-2.six
	drcssixel-test -c A -q -d 8x16 ./tileset16-2.six > font-2.txt
	cat font-2.txt
	ruby ../mogeRPG/png2sixel.rb tileset16-3.png  > tileset16-3.six
	drcssixel-test -c B -q -d 8x16 ./tileset16-3.six > font-3.txt
	cat font-3.txt
