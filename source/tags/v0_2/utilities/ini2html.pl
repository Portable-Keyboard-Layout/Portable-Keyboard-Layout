use encoding "utf8", STDOUT => "utf8";
use diagnostics;
use utf8;
use warnings;
use strict;
use Config::IniHash;
use ini2html::Button;
use ini2html::ButtonPosition;

my $INIFILE = 'layout.ini';
my $HTMLFILE = 'layout.html';
my $TEMPLATE = '';

###############################################################################################

{ # load template
	open(TPL, '<utf8', 'ini2html/template.html');
	binmode TPL;
	$TEMPLATE = join '', <TPL>;
	close TPL;
}

my $layout = ReadINI $INIFILE;

my $BUTTONS;
my @ROWLENGTH = (13,13,12,12,7);
$BUTTONS->[0]->[$_] = ini2html::Button->new('disabled') for(0..12);
$BUTTONS->[0]->[13] = ini2html::Button->new('normal', 'BackSpace');
$BUTTONS->[1]->[$_] = ini2html::Button->new('disabled') for(1..13);
$BUTTONS->[1]->[0] = ini2html::Button->new('normal', 'Tab');
$BUTTONS->[2]->[$_] = ini2html::Button->new('disabled') for(1..11);
$BUTTONS->[2]->[0] = ini2html::Button->new('normal', 'CapsLock');
$BUTTONS->[2]->[12] = ini2html::Button->new('normal', 'Enter');
$BUTTONS->[3]->[0] = ini2html::Button->new('modifier', 'LShift');
$BUTTONS->[3]->[$_] = ini2html::Button->new('disabled') for(1..11);
$BUTTONS->[3]->[12] = ini2html::Button->new('modifier', 'RShift');
$BUTTONS->[4]->[0] = ini2html::Button->new('modifier', 'LCtrl');
$BUTTONS->[4]->[1] = ini2html::Button->new('modifier', 'LWin');
$BUTTONS->[4]->[2] = ini2html::Button->new('modifier', 'LAlt');
$BUTTONS->[4]->[3] = ini2html::Button->new('normal', 'Space');
$BUTTONS->[4]->[4] = ini2html::Button->new('modifier', 'RAlt');
$BUTTONS->[4]->[5] = ini2html::Button->new('modifier', 'RWin');
$BUTTONS->[4]->[6] = ini2html::Button->new('normal', 'Menu');
$BUTTONS->[4]->[7] = ini2html::Button->new('modifier', 'RCtrl');

my @SHIFTSTATES = split /:/, ($layout->{global}->{shiftstates}.':8:9');
my $hasCapsState = 0;
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

	my $currmode = 0;
	foreach ( @modes ) {
		$button->newMode( $SHIFTSTATES[ $currmode ], $_ );
		if ( substr($button->mode($SHIFTSTATES[ $currmode ])->label(), 0, 2) eq 'dk') {
			my $dk = substr $button->mode($SHIFTSTATES[ $currmode ])->label(), 2;
			my $l = $layout->{"deadkey".$dk}->{0}."\n";
			$l =~ s/\s+;.*//;
			$button->mode($SHIFTSTATES[ $currmode ])->label(chr($l));
			$button->mode($SHIFTSTATES[ $currmode ])->type('deadkey');
		}
		$currmode++;
	}
	my ( $r, $c ) = buttonPosition( $sc );
	$BUTTONS->[$r]->[$c] = $button;
}

{ # Fingers
	my ($r,$c);
	for $r (0..3) {
		my @fingers = split //, (($layout->{fingers}->{'row'.($r+1)} or '') . '8888888888888888');
		my $modif = ($r==3?-1:0);
		$c = 0;
		foreach (0..$ROWLENGTH[$r]) {
			$BUTTONS->[$r]->[$c]->finger($fingers[$c+$modif]);
			$c++;
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


my $html = '';
my @states = @SHIFTSTATES;
if ( 1 || !$hasCapsState ) {
	pop @states;
	pop @states;
}
foreach ( @states ) {
	next if $_ == 2;
	my $state = $_;
	$html .= "\n".'<div>';
	$html .= '<div style="float: left; clear: left;">&nbsp;</div>'."\n";
	for my $r ( 0 .. 4) {
		$html .= '<div style="float: left; clear: left;">&nbsp;</div>'."\n";
		for my $c ( 0 .. $ROWLENGTH[$r] ) {
			my $button = $BUTTONS->[$r]->[$c];
			$html .= "\n";
			my $label = '';
			my $classes = '';
			my $style = '';
			
			if ( $button->type() eq 'disabled' ) {
				$label = '&nbsp;';
			} elsif ( $button->label() ne '' ) {
				$label = $button->label();
			} else {
				$label = $button->mode($state)->label();
			}
			$label =~ s/&/&amp;/g;
			$label =~ s/</&lt;/g;
			$label =~ s/>/&gt;/g;
			
			if ( $button->type() eq 'modifier' ) {
				$classes .= ' modifier';
			} elsif ( $button->label() ne '' or $button->mode($state)->type() eq 'special' ) {
				$classes .= ' special';
			}
			if ( $button->label() eq '' and $button->mode($state)->type() eq 'deadkey' ) {
				$classes .= ' deadkey';
			} else {
				$classes .= ' finger' . $button->finger();
			}
			
			$style .= 'width: 2em;' if ( $r == 0 && $c == 13 );
			$style .= 'width: 1.5em;' if ( $r == 1 && $c == 0 );
			$style .= 'width: 1.5em;' if ( $r == 1 && $c == 13 );
			$style .= 'width: 1.9em;' if ( $r == 2 && $c == 0 );
			$style .= 'width: 2.35em;' if ( $r == 2 && $c == 12 );
			$style .= 'width: 1.25em;' if ( $r == 3 && $c == 0 );
			$style .= 'width: 3em;' if ( $r == 3 && $c == 12 );
			$style .= 'width: 1.25em;' if ( $r == 4 && $c != 3 );
			$style .= 'width: 7.6em;' if ( $r == 4 && $c == 3 );
			$html .= '<div class="button '.$classes.'" style="'.$style.'" title="'.$label.'"><div>'.$label.'</div></div>';
		}
	}
	$html .= '</div>'."\n";
}

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