
# Usage: generateAllImages.pl 

use diagnostics;
use utf8;
use warnings;
use strict;

use File::Basename;
use File::Copy;
use Cwd;

open( ALL, '>GenerateAllImages.bat' );
foreach ( <../layouts/*> ) {
	my $layoutDir = $_;
	if ( ! -r $layoutDir.'/layout.ini' ) {
		next;
	}
	print ALL 'call GenerateImages ' . basename( $layoutDir ) . "\n";
}
print ALL 'del GenerateAllImages.bat';
close( All );
