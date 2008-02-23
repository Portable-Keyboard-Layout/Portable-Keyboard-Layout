use diagnostics;
use utf8;
use warnings;
use strict;

use Config::IniHash;

# Usage: split_png.pl
my $origPng = '';
my $layout = ReadINI '../layout.ini';

# And set these values
my $x0 = 14;
my $y0 = 212;
my $height = 102;
my $width = 296;
my $dist = 14;

# And these, too
my @states = split /:/, $layout->{global}->{shiftstates};
my $isExtendMode = (( $layout->{global}->{extend_key} ) ? 1 : 0 );
my $deadkeys = 19; # it is too much, but easier to delete, than count every time...


my @filenames;
foreach (@states) {
	push @filenames, 'state'.$_ if $_ != 2;
}
push @filenames, 'extend' if $isExtendMode;
push @filenames, 'deadkey'.$_ foreach (1..$deadkeys);

unless ( $origPng ) {
	foreach ( <*.png> ) {
		if ( $origPng ) {
			die 'Two png files!';
		} else {
			$origPng = $_;
		}
	}
	unless ( $origPng ) {
		die 'There is no png file!';
	}
}

my $count = scalar @filenames;
foreach ( 0..@filenames-1 ) {
	my $filename = $filenames[$_];
	my $y = $y0 + ( $_ ) * ( $dist + $height );
	my $newPng = $filename . '.png';
	my $cmd = '"c:\Program Files\ImageMagick\convert.exe" '.$origPng ." -crop ${width}x${height}+$x0+$y " . $newPng;
	print $filename."\n";
	system($cmd);
	if ( -s $newPng < 3000 ) {
		unlink $newPng;
		last;
	}
}
