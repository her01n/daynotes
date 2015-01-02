default:
	valac --pkg gtk+-3.0 main.vala -o daynotes

clean:
	rm -rf daynotes
