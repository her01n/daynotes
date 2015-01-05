default:
	valac --pkg gtk+-3.0 main.vala -o daynotes 2>&1 | perl valac_remove_columns.pl

clean:
	rm -rf daynotes
