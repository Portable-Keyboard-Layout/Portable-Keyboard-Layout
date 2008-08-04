use encoding "utf8", STDOUT => "utf8";
use diagnostics;
use utf8;
use warnings;
use strict;

my $KLCFILE = $ARGV[0];
my $EXTEND_MODE = ( $ARGV[1] and $ARGV[1] eq 'vk' );
my $INIFILE = 'out/layout.ini';

my $LAYOUT  = '[layout]'."\n";
my $LIGATURE = ''."\n";
my $DEADKEYS = '';
my $GLOBAL = '[global]' . "\n";
my %INFORMATIONS = ();

####### Read informations #######

unless ( $KLCFILE ) {
	foreach ( <*.klc> ) {
		if ( $KLCFILE ) {
			die 'Two .klc files!';
		} else {
			$KLCFILE = $_;
		}
	}
}

open KLC, '<:encoding(utf-16)', $KLCFILE  or die "Can't open $KLCFILE: $!";;
my $ll = ''; # Last Line

while (<KLC>) {
	my $k;
	chomp;
	last if /^SHIFTSTATE/;
	next unless /^([A-Z]+)\s+(\S.+?)\s*$/;
	if ( $1 eq 'KBD') {
		my ($kc,$kb) = split /\t/,$2;
		$INFORMATIONS{layoutcode} = $kc;
		$INFORMATIONS{layoutname} = $kb;
		next;
	} elsif ( -1 == index ' COPYRIGHT COMPANY LOCALEID VERSION ', ' '.$1.' ') {
		next;
	} else {
		$k = $1;
	}
	$INFORMATIONS{(lc($k))} = $2;
}
foreach (keys %INFORMATIONS) { # remove quotes
	$INFORMATIONS{$_} = substr($INFORMATIONS{$_}, 1,-1) if ( $INFORMATIONS{$_} =~ /^".*"$/ )
}
$INFORMATIONS{homepage} = 'http://pkl.sourceforge.net/';
$INFORMATIONS{modified_after_generate} = 'no';
$INFORMATIONS{generated_from} = $KLCFILE;
$INFORMATIONS{generated_at} = gmtime;

my @SHIFTSTATES; # position => state
{
	while (<KLC>) { # Shift state
		chomp;
		last if /^LAYOUT/;
		next unless /^(\d+)\s+.+$/;
		push @SHIFTSTATES, $1;
	}
	$INFORMATIONS{shiftstates} = join ":", @SHIFTSTATES;
	push @SHIFTSTATES, 8; # SGCap + Key
	push @SHIFTSTATES, 9; # SGCap + Shift + Key
}

####### Read keymapper #######

$GLOBAL .= '; extend_key = CapsLock' . "\n";
$GLOBAL .= 'shiftstates = '. $INFORMATIONS{shiftstates} . "\n";
$GLOBAL .= 'img_width = 296' . "\n";
$GLOBAL .= 'img_height = 102' . "\n";

$LAYOUT .= ";scan = VK\tCapStat";
foreach ( split /:/, $INFORMATIONS{shiftstates}) {
	$LAYOUT .= "\t" . $_ . shiftStateName($_);
}
$LAYOUT .= "\tCaps\tCapsSh\n";
while (<KLC>) {
	chomp;
	if ( /^(LIGATURE|DEADKEY|KEYNAME)/ ) {
		$ll = $_;
		last;
	}
	s!\s*//.*$!!;
	my @parts = split /\s+/;
	
	next unless (@parts);
	my ($sc, $vk, $cap);
	($sc, $vk, $cap, @parts) = @parts;
	if ( $cap eq 'SGCap' ) {
		$cap = 8;
		local $_ = <KLC>;
		s!\s*//.*$!!;
		my @t = split/\s+/;
		splice @t, 0, 3;
		push @parts, @t;
	}
	$LAYOUT .= 'SC0'. $sc . ' = ';
	$LAYOUT .= $vk;
	$LAYOUT .= "\t" . $cap;
	for (my $i = 0; $i < @parts; $i++) {
		$LAYOUT .= "\t" . mapkey($parts[$i]);
	}
	$LAYOUT .= "\t" . '; QWERTY ' . qwertys($sc);
	$LAYOUT .= "\n";
}


####### Read dead keys #######

$ll =~ /^DEADKEY\s+(....)/;
my $dk = $1; # Current dead key
my $dkChr = ''; # DK%dkChr%...
my $newdk = 1;
while (<KLC>) {
	chomp;
	if ( /^DEADKEY\s+(....)/ ) {
		$dk = $1;
		$newdk = 1;
		next;
	} elsif ( /^KEYNAME/ ) {
		last;
	} elsif ( $newdk ) {
		$newdk = 0;
		$dkChr = DeadKeyNumber(hex $dk);
		$DEADKEYS .= "\n\n";
		$DEADKEYS .= '[deadkey'.$dkChr.']'."\n";
		$DEADKEYS .= sprintf('%-4s','0').' = '.sprintf('%4u',(hex $dk));
		$DEADKEYS .= "\t" . '; ' . myChr(hex $dk) ."\n";
	}
	s!\s*//.*$!!;
	my @parts = split /\s+/;
	next unless (@parts);
	$DEADKEYS .= sprintf('%-4s',(hex $parts[0])).' = ';
	$DEADKEYS .= sprintf('%4u',(hex $parts[1]));
	$DEADKEYS .= "\t" . '; '.myChr(hex $parts[0]).' -> '.myChr(hex $parts[1])."\n";
}
close KLC;


####### Write to ini file #######

open INI, '>:utf8', $INIFILE;
binmode INI, ':utf8';
print INI <<'EOF';
;
; Keyboard Layout definition for
; Portable Keyboard Layout 
; http://pkl.sourceforge.net
;

[informations]
EOF
foreach
	(
		'layoutname',
		'layoutcode',
		'localeid',
		'',
		'copyright',
		'company',
		'homepage',
		'version',
		'',
		'generated_at',
		'generated_from',
		'modified_after_generate'
	) {
	if ( $_ eq '' )
	{
		print INI "\n";
	} else {
		print INI sprintf('%-20s',$_).' = '.$INFORMATIONS{$_}."\n";
	}
}
print INI "\n\n";
print INI $GLOBAL;
print INI "\n\n";
print INI <<'EOF';
[fingers]
row1 = 1123445567888
row2 = 1123445567888
row3 = 1123445567888
row4 = 11234455678

EOF
print INI $LAYOUT;
print INI "\n\n";
print INI $LIGATURE;
print INI "\n\n";
print INI $DEADKEYS;
print INI "\n\n";
close INI;

########################### Functions ###########################

sub mapkey
{
	my $data = shift;
	my $un; # Unicode number
	my $isDeadkey = 0;
	
	return '--' if $data eq '-1';
	return '%%' if $data eq '%%';
	if ( substr($data, -1) eq '@' ) {
		$data = substr($data, 0, -1);
		$isDeadkey = 1
	}
	if ( 1 == length($data) ) {
		$un = ord $data;
	} else {
		$un = hex substr($data,0,4);
	}
	return 'dk'. DeadKeyNumber($un) if $isDeadkey;
	return '*{Enter}' if $un == 13;
	return '*{Tab}' if $un == 9;
	return '={Space}' if $un == 32;
	return myChr($un);
}


{ # DeadKeyNumber
	my %DKN = ();
	my $mDK = 0;
	sub DeadKeyNumber
	{
		my $k = shift;
		$DKN{$k} = (++$mDK) unless defined $DKN{$k};
		return $DKN{$k};
	}
}

{ # qwertys
	my %QC = ();
	sub qwertys
	{
		%QC = (
			'02' => '1!', '03' => '2@', '04' => '3#', '05' => '4$', 
			'06' => '5%', '07' => '6^', '08' => '7&', '09' => '8*', 
			'0a' => '9(', '0b' => '0)', '0c' => '-_', '0d' => '=+', 
			'10' => 'qQ', '11' => 'wW', '12' => 'eE', '13' => 'rR', 
			'14' => 'tT', '15' => 'yY', '16' => 'uU', '17' => 'iI', 
			'18' => 'oO', '19' => 'pP', '1a' => '[{', '1b' => ']}', 
			'1e' => 'aA', '1f' => 'sS', '20' => 'dD', '21' => 'fF', 
			'22' => 'gG', '23' => 'hH', '24' => 'jJ', '25' => 'kK', 
			'26' => 'lL', '27' => ';:', '28' => '\'"', '29' => '`~', 
			'2b' => '\|', '2c' => 'zZ', '2d' => 'xX', '2e' => 'cC', 
			'2f' => 'vV', '30' => 'bB', '31' => 'nN', '32' => 'mM', 
			'33' => ',<', '34' => '.>', '35' => '/?', '39' => 'Space', 
			'56' => 'OEM_102', '53' => 'Decimal in Numpad', 
		) unless %QC;
		my $sc = shift;
		return $QC{($sc)};
	}
}


{ # virtualkey
	my %VKS = ();
	sub virtualKey
	{
		%VKS = (
			'LBUTTON' => '01', 'RBUTTON' => '02', 'CANCEL' => '03', 'MBUTTON' => '04', 'XBUTTON1' => '05', 'XBUTTON2' => '06', 'BACK' => '08', 'TAB' => '09', 'CLEAR' => '0C', 'RETURN' => '0D', 'SHIFT' => '10', 'CONTROL' => '11', 'MENU' => '12', 'PAUSE' => '13', 'CAPITAL' => '14', 'KANA' => '15', 'HANGUEL' => '15', 'HANGUL' => '15', 'JUNJA' => '17', 'FINAL' => '18', 'HANJA' => '19', 'KANJI' => '19', 'ESCAPE' => '1B', 'CONVERT' => '1C', 'NONCONVERT' => '1D', 'ACCEPT' => '1E', 'MODECHANGE' => '1F', 'SPACE' => '20', 'PRIOR' => '21', 'NEXT' => '22', 'END' => '23', 'HOME' => '24', 'LEFT' => '25', 'UP' => '26', 'RIGHT' => '27', 'DOWN' => '28', 'SELECT' => '29', 'PRINT' => '2A', 'EXECUTE' => '2B', 'SNAPSHOT' => '2C', 'INSERT' => '2D', 'DELETE' => '2E', 'HELP' => '2F', '0' => '30', '1' => '31', '2' => '32', '3' => '33', '4' => '34', '5' => '35', '6' => '36', '7' => '37', '8' => '38', '9' => '39', 'A' => '41', 'B' => '42', 'C' => '43', 'D' => '44', 'E' => '45', 'F' => '46', 'G' => '47', 'H' => '48', 'I' => '49', 'J' => '4A', 'K' => '4B', 'L' => '4C', 'M' => '4D', 'N' => '4E', 'O' => '4F', 'P' => '50', 'Q' => '51', 'R' => '52', 'S' => '53', 'T' => '54', 'U' => '55', 'V' => '56', 'W' => '57', 'X' => '58', 'Y' => '59', 'Z' => '5A', 'LWIN' => '5B', 'RWIN' => '5C', 'APPS' => '5D', 'SLEEP' => '5F', 'NUMPAD0' => '60', 'NUMPAD1' => '61', 'NUMPAD2' => '62', 'NUMPAD3' => '63', 'NUMPAD4' => '64', 'NUMPAD5' => '65', 'NUMPAD6' => '66', 'NUMPAD7' => '67', 'NUMPAD8' => '68', 'NUMPAD9' => '69', 'MULTIPLY' => '6A', 'ADD' => '6B', 'SEPARATOR' => '6C', 'SUBTRACT' => '6D', 'DECIMAL' => '6E', 'DIVIDE' => '6F', 'F1' => '70', 'F2' => '71', 'F3' => '72', 'F4' => '73', 'F5' => '74', 'F6' => '75', 'F7' => '76', 'F8' => '77', 'F9' => '78', 'F10' => '79', 'F11' => '7A', 'F12' => '7B', 'F13' => '7C', 'F14' => '7D', 'F15' => '7E', 'F16' => '7F', 'F17' => '80', 'F18' => '81', 'F19' => '82', 'F20' => '83', 'F21' => '84', 'F22' => '85', 'F23' => '86', 'F24' => '87', 'NUMLOCK' => '90', 'SCROLL' => '91', 'OEM_NEC_EQUAL' => '92', 'OEM_FJ_JISHO' => '92', 'OEM_FJ_MASSHOU' => '93', 'OEM_FJ_TOUROKU' => '94', 'OEM_FJ_LOYA' => '95', 'OEM_FJ_ROYA' => '96', 'LSHIFT' => 'A0', 'RSHIFT' => 'A1', 'LCONTROL' => 'A2', 'RCONTROL' => 'A3', 'LMENU' => 'A4', 'RMENU' => 'A5', 'BROWSER_BACK' => 'A6', 'BROWSER_FORWARD' => 'A7', 'BROWSER_REFRESH' => 'A8', 'BROWSER_STOP' => 'A9', 'BROWSER_SEARCH' => 'AA', 'BROWSER_FAVORITES' => 'AB', 'BROWSER_HOME' => 'AC', 'VOLUME_MUTE' => 'AD', 'VOLUME_DOWN' => 'AE', 'VOLUME_UP' => 'AF', 'MEDIA_NEXT_TRACK' => 'B0', 'MEDIA_PREV_TRACK' => 'B1', 'MEDIA_STOP' => 'B2', 'MEDIA_PLAY_PAUSE' => 'B3', 'LAUNCH_MAIL' => 'B4', 'LAUNCH_MEDIA_SELECT' => 'B5', 'LAUNCH_APP1' => 'B6', 'LAUNCH_APP2' => 'B7', 'OEM_1' => 'BA', 'OEM_PLUS' => 'BB', 'OEM_COMMA' => 'BC', 'OEM_MINUS' => 'BD', 'OEM_PERIOD' => 'BE', 'OEM_2' => 'BF', 'OEM_3' => 'C0', 'OEM_4' => 'DB', 'OEM_5' => 'DC', 'OEM_6' => 'DD', 'OEM_7' => 'DE', 'OEM_8' => 'DF', 'OEM_102' => 'E2', 'PROCESSKEY' => 'E5', 'PACKET' => 'E7', 'OEM_RESET' => 'E9', 'OEM_JUMP' => 'EA', 'OEM_PA1' => 'EB', 'OEM_PA2' => 'EC', 'OEM_PA3' => 'ED', 'OEM_WSCTRL' => 'EE', 'OEM_CUSEL' => 'EF', 'OEM_ATTN' => 'F0', 'OEM_FINNISH' => 'F1', 'OEM_COPY' => 'F2', 'OEM_AUTO' => 'F3', 'OEM_ENLW' => 'F4', 'OEM_BACKTAB' => 'F5', 'ATTN' => 'F6', 'CRSEL' => 'F7', 'EXSEL' => 'F8', 'EREOF' => 'F9', 'PLAY' => 'FA', 'ZOOM' => 'FB', 'NONAME' => 'FC', 'PA1' => 'FD', 'OEM_CLEAR' => 'FE'
		) unless %VKS;
		return $VKS{(shift)};
	}
}

sub shiftStateName
{ 
	my $num = shift;
	my $res = '';
	$res .= 'Cap' if $num & 8;
	if ( ($num & 6) == 6 ) {
		$res .= 'AGr';
	} else {
		$res .= 'Ctrl' if $num & 2;
	}
	$res .= 'Sh' if $num & 1;
	$res = 'Norm' unless $res;
	return $res;
}

sub myChr
{
	return Encode::encode("utf8", chr shift);
}