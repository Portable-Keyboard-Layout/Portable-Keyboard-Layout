use encoding "utf8", STDOUT => "utf8";
use diagnostics;
use utf8;
use warnings;
use strict;
use Config::IniHash;
use ini2html::Button;
use ini2html::ButtonPosition;
use locale;

my $INIFILE = 'out/layout.ini';
my $HTMLFILE = 'out/layout.html';
my $TEMPLATE = '';

###############################################################################################
{
	my %shortNames = (
		'backspace' => '<span class="special">'.chr(0x2190).'</span>',
		'lshift' => '<span class="special">'.chr(0x21e7).'</span>',
		'capslock' => '<span class="special">'.chr(0x21ea).'</span>',
		'enter' => '<span class="special">'.chr(0x21b5).'</span>',
		'lctrl' => 'LCt',
		'lwin' => 'LW',
		'lalt' => 'LAlt',
		'altgr' => 'AGr',
		'rctrl' => 'RCt',
		'rwin' => 'RW',
		'ralt' => 'RAlt',
		'tab' => '<span class="special">'.chr(0x21b9).'</span>',
		
	);
	sub shortLabel($)
	{
		my $v = shift;
		return $shortNames{ lc $v } || $v;
	}
}
###############################################################################################

{ # load template
	open(TPL, '<utf8', 'ini2html/template.html');
	binmode TPL;
	$TEMPLATE = join '', <TPL>;
	close TPL;
}

my $layout = ReadINI $INIFILE;

my %LETTERS; # Letter => [ row, col ]
my %SHIFTLETTERS; # Letter (with Shift) => [ row, col ]
my %DEADKEYPOSITIONS; # deadkey number => [ row, col ]
my $BUTTONS;
$BUTTONS->[0]->[$_] = ini2html::Button->new('disabled') for(0..13);
$BUTTONS->[1]->[$_] = ini2html::Button->new('disabled') for(1..13);
$BUTTONS->[2]->[$_] = ini2html::Button->new('disabled') for(1..12);
$BUTTONS->[3]->[$_] = ini2html::Button->new('disabled') for(1..11);
$BUTTONS->[1]->[0] = ini2html::Button->new('normal', 'Tab');
$BUTTONS->[2]->[0] = ini2html::Button->new('normal', 'Capslock');
$BUTTONS->[3]->[0] = ini2html::Button->new('modifier', 'LShift');
$BUTTONS->[3]->[12] = ini2html::Button->new('modifier', 'RShift');
$BUTTONS->[4]->[0] = ini2html::Button->new('modifier', 'LCtrl');
$BUTTONS->[4]->[1] = ini2html::Button->new('modifier', 'LWin');
$BUTTONS->[4]->[2] = ini2html::Button->new('modifier', 'LAlt');
$BUTTONS->[4]->[3] = ini2html::Button->new('normal', 'Space');
$BUTTONS->[4]->[4] = ini2html::Button->new('modifier', 'RAlt');
$BUTTONS->[4]->[5] = ini2html::Button->new('modifier', 'RWin');
$BUTTONS->[4]->[6] = ini2html::Button->new('normal', 'Menu');
$BUTTONS->[4]->[7] = ini2html::Button->new('modifier', 'RCtrl');

my $enterMode = $layout->{fingers}->{enter_mode} || 1;
if ( !defined $enterMode or $enterMode== 1 ) {
	$BUTTONS->[0]->[13] = ini2html::Button->new('normal', 'Backspace');
	$BUTTONS->[2]->[12] = ini2html::Button->new('normal', 'Enter');
} elsif ( $enterMode== 0 ) {
	$BUTTONS->[0]->[14] = ini2html::Button->new('normal', 'Backspace');
	$BUTTONS->[1]->[13] = ini2html::Button->new('normal', 'Enter');
	$BUTTONS->[2]->[12] = ini2html::Button->new('normal', 'Enter');
} elsif ( $enterMode== 2 ) {
	$BUTTONS->[0]->[13] = ini2html::Button->new('normal', 'Backspace');
	$BUTTONS->[1]->[13] = ini2html::Button->new('normal', 'Enter');
	$BUTTONS->[2]->[13] = ini2html::Button->new('normal', 'Enter');
}
buttonPositionEnterMode($enterMode);

my @SHIFTSTATES = split /:/, ($layout->{global}->{shiftstates}.':8:9');
my $hasCapsState = 0;
my $hasAltGr     = 0;
foreach ( @SHIFTSTATES ) {$hasAltGr = 1 if $_&6 == 6;}
while ( my ($sc, $def) = each(%{$layout->{layout}} ) )
{
	$def =~ s/\t; [^\t]+$//;
	my ( $vk, $caps, @modes ) = split /\t/, $def;
	my $type = 'normal';
	my $label = '';

	$caps = -1 if lc($caps) eq 'vk' || lc($caps) eq 'virtualkey';
	$caps = -2 if lc($caps) eq 'modifier';
	if ( $caps == -1 ) {
		$type = 'vk';
		$label = $vk;
		$vk = '';
	} elsif ( $caps == -2) {
		$type = 'modifier';
		$label = $vk;
		$vk = '';
	} elsif ( $caps == 8 ) {
		$hasCapsState = 1;
	}
	my $button = ini2html::Button->new($type, $label, $vk, $caps);
	my ( $r, $c ) = @{buttonPosition( $sc )->[0]};
	my $currmode = 0;
	foreach ( @modes ) {
		$button->newMode( $SHIFTSTATES[ $currmode ], $_ );
		if ( substr($button->mode($SHIFTSTATES[ $currmode ])->label(), 0, 2) eq 'dk') {
			my $dk = substr $button->mode($SHIFTSTATES[ $currmode ])->label(), 2;
			my $l = $layout->{"deadkey".$dk}->{0}."\n";
			$l =~ s/\s+;.*//;
			$button->mode($SHIFTSTATES[ $currmode ])->label(myChr($l));
			$button->mode($SHIFTSTATES[ $currmode ])->type('deadkey');
			$DEADKEYPOSITIONS{$dk} = [ $r, $c ];
		}
		$currmode++;
	}
	if ( $button->mode(0) ) {
		my $l = $button->mode(0)->label();
		$LETTERS{$l} = [$r, $c] if length $l == 1;
	}
	if ( $button->mode(1) ) {
		my $l = $button->mode(1)->label();
		$SHIFTLETTERS{$l} = [$r, $c] if length $l == 1;
	}
	my @bpos = @{buttonPosition( $sc )};
	while (@bpos) {
		my ( $r, $c ) = @{(shift @bpos)};
		$BUTTONS->[$r]->[$c] = $button;
	}
}
if ( 1 || !$hasCapsState ) {
	pop @SHIFTSTATES;
	pop @SHIFTSTATES;
}

{ # Fingers
	for my $r (0..3) {
		my @fingers = split //, (($layout->{fingers}->{'row'.($r+1)} or '') . '8888888888888888');
		my $modif = ($r==3?-1:0);
		foreach (0..@{$BUTTONS->[$r]}-1) {
			$BUTTONS->[$r]->[$_]->finger($fingers[$_+$modif]);
		}
	}
	$BUTTONS->[3]->[0]->finger(1);
	$BUTTONS->[4]->[0]->finger(1);
	$BUTTONS->[4]->[1]->finger(1);
	$BUTTONS->[4]->[2]->finger(1);
	$BUTTONS->[4]->[3]->finger(9);
	$BUTTONS->[4]->[4]->finger(8);
	$BUTTONS->[4]->[5]->finger(8);
	$BUTTONS->[4]->[6]->finger(8);
	$BUTTONS->[4]->[7]->finger(8);
}

if ( $layout->{global}->{extend_key} ) { # Extend mode
	my %extendKeys;
	if ( $layout->{extend} ) {
		%extendKeys = %{$layout->{extend}};
	} elsif ( -e 'pkl.ini' ) {
		my $pkl = ReadINI 'pkl.ini';
		%extendKeys = %{$pkl->{extend}};
	} elsif ( -e '../pkl.ini' ) {
		my $pkl = ReadINI '../pkl.ini';
		%extendKeys = %{$pkl->{extend}};
	}
	
	push @SHIFTSTATES, 100;
	while ( my ($sc, $def) = each(%extendKeys) )
	{
		$def =~ s/\t; [^\t]+$//;
		my @bpos = @{buttonPosition( $sc )};
		while (@bpos) {
			my ( $r, $c ) = @{(shift @bpos)};
			$BUTTONS->[$r]->[$c]->newMode( 100, '*{'.$def.'}' );
		}
	}
	$BUTTONS->[4]->[3]->newMode( 100, 'EXTEND MODE' );
}

{ # Dead keys
	my $deadkey = 1;
	while ( $layout->{'deadkey'.$deadkey} ) {
		push @SHIFTSTATES, 100+$deadkey;
		while ( my ($base, $new) = each(%{$layout->{'deadkey'.$deadkey}} ) ) {
			next unless defined $LETTERS{chr($base)};
			$new =~ s/\t; [^\t]+$//;
			my ($r, $c) = @{$LETTERS{chr($base)}};
			$BUTTONS->[$r]->[$c]->newMode( 100+$deadkey, myChr($new) );
		}
		{ # Space and button of the current deadkey
			my $new = $layout->{'deadkey'.$deadkey}->{0};
			$new =~ s/\t; [^\t]+$//;
			$BUTTONS->[4]->[3]->newMode( 100+$deadkey, myChr($new) );
			$BUTTONS->[4]->[3]->mode( 100+$deadkey )->type('deadkey');
			$BUTTONS->[4]->[6]->newMode( 100+$deadkey, $deadkey );
			$BUTTONS->[4]->[6]->mode( 100+$deadkey )->type('special');
		}
		
		push @SHIFTSTATES, 200+$deadkey;
		while ( my ($base, $new) = each(%{$layout->{'deadkey'.$deadkey}} ) ) {
			next unless defined $SHIFTLETTERS{chr($base)};
			$new =~ s/\t; [^\t]+$//;
			my ($r, $c) = @{$SHIFTLETTERS{chr($base)}};
			$BUTTONS->[$r]->[$c]->newMode( 200+$deadkey, myChr($new) );
		}
		{ # Space and button of the current deadkey
			my $new = $layout->{'deadkey'.$deadkey}->{0};
			$new =~ s/\t; [^\t]+$//;
			$BUTTONS->[4]->[3]->newMode( 200+$deadkey, myChr($new) );
			$BUTTONS->[4]->[3]->mode( 200+$deadkey )->type('deadkey');
			$BUTTONS->[4]->[6]->newMode( 200+$deadkey, $deadkey );
			$BUTTONS->[4]->[6]->mode( 200+$deadkey )->type('special');
		}
		++$deadkey;
	}
}

my $html = '';
$html .= '<div id="layouts">'."\n";
foreach ( @SHIFTSTATES ) {
	next if $_ == 2;
	next if ($_ < 100 && ($_&8) == 8 && !$hasCapsState);
	$html .= '<div class="layout">'."\n";
	my $state = $_;
	for my $r ( 0 .. 4) {
		$html .= '<table class="onerow"><tr>'."\n";
		for my $c ( 0 .. @{$BUTTONS->[$r]}-1 ) {
			my $button = $BUTTONS->[$r]->[$c];
			$html .= "\n";
			my $label = '';
			my $classes = '';
			my $style = '';
			
			if ( $button->type() eq 'disabled' ) {
				$label = ' ';
			} elsif ( $button->label() ne '' ) {
				$label = $button->label();
				$label = 'AltGr' if $hasAltGr && lc $label eq 'ralt';
			} elsif ( $button->mode($state) ) {
				$label = $button->mode($state)->label();
			} else {
				$label = '';
			}
			
			if ( $button->type() eq 'modifier' ) {
				$classes .= ' modifier';
			} elsif ( $button->label() ne '' or $button->mode($state) && $button->mode($state)->type() eq 'special' ) {
				$classes .= ' special';
			}
			if ( $state < 100 and ( $button->label() =~ /Shift/i && $state&1 or $button->label() =~ /RAlt/i && $state>=6 ) ) {
				$classes .= ' pressed';
			} elsif ( $state >= 200 and $button->label() =~ /Shift/i) {
				$classes .= ' pressed';
			} elsif ( $button->label() eq '' and defined $button->mode($state) and $button->mode($state)->type() eq 'deadkey' ) {
				$classes .= ' deadkey';
			} else {
				$classes .= ' finger' . $button->finger();
			}
			
			$label =~ s/&/&amp;/g;
			$label =~ s/</&lt;/g;
			$label =~ s/>/&gt;/g;
			
			{
				my $w = buttonWidth( $r, $c );
				$style .= 'width: '. $w . 'em;' if ( $w != 1 );
			}
			
			$html .= '<td class="button '.$classes.'" style="'.$style.'" title="'.$label.'"><div>'.shortLabel($label).'</div></td>';
		}
		$html .= "\n".'</tr></table>'."\n";
	}
	$html .= '</div>'."\n";
}
$html .= '<p>© <a href="http://pkl.sourceforge.net/">pkl.sourceforge.net</a></p>'."\n";
$html .= '</div>';

open(HTML, '>:utf8', $HTMLFILE);
binmode HTML, ':utf8';
$_ = $TEMPLATE;
s/#layoutname#/$layout->{informations}->{layoutname}/g;
s/#version#/$layout->{informations}->{version}/g;
s/#homepage#/$layout->{informations}->{homepage}/g;
s/#copyright#/$layout->{informations}->{copyright}/g;
s/#company#/$layout->{informations}->{company}/g;
s/#modes#/$html/;
print HTML $_;
close HTML;



sub myChr
{
	return Encode::encode("utf8", chr shift);
}