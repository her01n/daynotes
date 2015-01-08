#!/usr/bin/perl

system("mkdir -p bin");
system("valac --pkg gtk+-3.0 main.vala daynotes.vala -o bin/daynotes 2>&1 | perl valac_remove_columns.pl");
system("valac --pkg gtk+-3.0 calendar_server.vala daynotes.vala -o bin/calendar_server 2>&1 | perl valac_remove_columns.pl");

