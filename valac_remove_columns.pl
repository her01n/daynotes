#!/usr/bin/perl

while (<>) {
    if (/^(.*):(\d+).(\d+)-(\d+).(\d+):(.*)$/) {
        print "$1:$2:$6\n";
    } else {
        print $_;
    }
}

