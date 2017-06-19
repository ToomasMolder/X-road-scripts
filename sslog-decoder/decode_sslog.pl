#!/usr/bin/perl
use MIME::Base64;
use warnings;
use diagnostics;

while (<>) {
        my ($jama,$jura,$sisu,$aeg) = split (" ", $_);
        my $s = decode_base64($sisu);
        $s =~ s/\n//g;
        my ($m) = ( $s =~ /<?xml(.*)>$/ );
        if ( defined $m ) {
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($aeg);
                printf "%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1,$mday,$hour,$min,$sec;
                print " <?xml $m >\n";
                }
        }
