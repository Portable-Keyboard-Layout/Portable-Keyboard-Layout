package ini2html::Button;

use 5.8.0;
use strict;
use warnings;

sub new($;$$$)
{
	my $class = shift;
	my $type = shift || 'disabled'; # disabled, nomal, modifier
	my $label = shift || ''; # Label for modifiers...
	my $vk = shift || 'ff'; # VirtualKey
	my $caps = shift || 0; # CapsState
	
	my $self = {
		type => $type,
		vk => $vk,
		label => $label,
		caps => $caps,
		finger => 0,
	};
	bless $self, $class;
	$self;
}

sub mode( $$;$ )
{
	my $self = shift;
	my $mode = shift;
	
	$self->{$mode} = shift if ( @_ );
	return $self->{$mode}
}

sub newMode( $$$ )
{
	my $self = shift;
	my $mode = shift;
	
	$self->{$mode} = ini2html::Button::Mode->newMode(shift);
	return $self->{$mode}
}


sub vk( $;$ )
{
	my $self = shift;
	$self->{vk} = shift if ( @_ );
	return $self->{vk};
}

sub caps( $;$ )
{
	my $self = shift;
	$self->{caps} = shift if ( @_ );
	return $self->{caps};
}


sub finger( $;$ )
{
	my $self = shift;
	$self->{finger} = shift if ( @_ );
	return $self->{finger};
}

sub label( $;$ )
{
	my $self = shift;
	$self->{label} = shift if ( @_ );
	return $self->{label};
}

sub type( $;$ )
{
	my $self = shift;
	$self->{type} = shift if ( @_ );
	return $self->{type};
}

package ini2html::Button::Mode;

sub new($;$$)
{
	my $class = shift;
	my $type = 'disabled'; # disabled, ligature, normal, special
	my $label = '';
	if ( @_ ) {
		$type = shift;
		if ( @_ ) {
			$label = shift;
		}
	}
	my $self = {
		type => $type,
		label => $label
	};
	bless $self, $class;
	$self;
}


{
	my %shortNames = (
		left => chr(0x2190),
		up   => chr(0x2191),
		right=> chr(0x2192),
		down => chr(0x2193),
	);
	my %longNames = (
		'^x' => 'Cut',
		'^c' => 'Copy',
		'^v' => 'Paste',
		'^s' => 'Save',
		'{wheelleft}' => chr(0x2190),
		'{wheelup}'   => chr(0x2191),
		'{wheelright}'=> chr(0x2192),
		'{wheeldown}' => chr(0x2193),
	);

sub newMode( $$ )
{
	my $class = shift;
	my $str = shift;
	my $type;
	my $label = '';
	
	if ( length($str) == 1 ) {
		$type = 'normal';
		$label = $str;
	} elsif ( $str eq '' || $str eq '--' ) {
		$type = 'disabled';
		$label = '';
	} elsif ( substr( $str, 0, 1 ) eq '%' ) {
		$type = 'ligature';
		$label = substr( $str, 1 );
	} else {
		$type = 'normal';
		if ( substr( $str, 0, 1 ) eq '=' || substr( $str, 0, 1 ) eq '*' ) {
			$type = 'special';
			$label = $str = substr( $str, 1 );
			if ( $longNames{ lc $str } ) {
				$label = $longNames{ lc $str };
				$str = '';
			}
		}
		if ( $str eq '' ) {
			# nothing.
		} elsif ( substr( $str, 0, 1 ) eq '{' and substr( $str, -1 ) eq '}' and substr( $str, 1, -1 ) !~ /[{}]/ ) {
			my $n = lc substr( $str, 1, -1 );
			if ( defined $shortNames{$n} ) {
				$label = $shortNames{$n};
				$type = 'normal';
			} else {
				$label = ucfirst $n;
				$type = 'special';
			}
		} elsif ( $str !~ /[^{][!^+#]/ and $str !~ /[!^+#][^}]/ ) {
			$label = $str;
			$label =~ s/{\+}/+/g;
			$label =~ s/{^}/^/g;
			$label =~ s/{#}/#/g;
			$label =~ s/{!}/!/g;
			$type = 'normal';
		} else {
			$label = $str;
		}
	}
	return $class->new( $type, $label );
}
} # sub newMode + %shortNames

sub type( $;$ )
{
	my $self = shift;
	$self->{type} = shift if ( @_ );
	return $self->{type};
}

sub label( $;$ )
{
	my $self = shift;
	$self->{label} = shift if ( @_ );
	return $self->{label};
}
