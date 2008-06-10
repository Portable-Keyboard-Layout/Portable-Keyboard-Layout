{ # sub buttonPosition, buttonPositionEnterMode
	my %buttonPositions = (
		enterMode => 1,
		sc029 => [[0,0]],
		sc002 => [[0,1]],
		sc003 => [[0,2]],
		sc004 => [[0,3]],
		sc005 => [[0,4]],
		sc006 => [[0,5]],
		sc007 => [[0,6]],
		sc008 => [[0,7]],
		sc009 => [[0,8]],
		sc00a => [[0,9]],
		sc00b => [[0,10]],
		sc00c => [[0,11]],
		sc00d => [[0,12]],
		sc00e => [[0,13]],
		backspace => [[0,13]],

		sc00f =>[[1,0]],
		tab => [[1,0]],
		sc010 => [[1,1]],
		sc011 => [[1,2]],
		sc012 => [[1,3]],
		sc013 => [[1,4]],
		sc014 => [[1,5]],
		sc015 => [[1,6]],
		sc016 => [[1,7]],
		sc017 => [[1,8]],
		sc018 => [[1,9]],
		sc019 => [[1,10]],
		sc01a => [[1,11]],
		sc01b => [[1,12]],
		sc02b => [[1,13]],

		capslock => [[2,0]],
		sc03a => [[2,0]],
		sc01e => [[2,1]],
		sc01f => [[2,2]],
		sc020 => [[2,3]],
		sc021 => [[2,4]],
		sc022 => [[2,5]],
		sc023 => [[2,6]],
		sc024 => [[2,7]],
		sc025 => [[2,8]],
		sc026 => [[2,9]],
		sc027 => [[2,10]],
		sc028 => [[2,11]],
		enter => [[2,12]],

		lshift => [[3,0]],
		sc02a => [[3,0]],
		sc056 => [[3,1]],
		sc02c => [[3,2]],
		sc02d => [[3,3]],
		sc02e => [[3,4]],
		sc02f => [[3,5]],
		sc030 => [[3,6]],
		sc031 => [[3,7]],
		sc032 => [[3,8]],
		sc033 => [[3,9]],
		sc034 => [[3,10]],
		sc035 => [[3,11]],
		sc136 => [[3,12]],
		rshift => [[3,12]],
		
		sc01d => [[4,0]],
		lctrl => [[4,0]],
		sc15b => [[4,1]],
		lwin => [[4,1]],
		sc038 => [[4,2]],
		lalt => [[4,2]],
		sc039 => [[4,3]],
		space => [[4,3]],
		ralt => [[4,4]],
		altgr => [[4,4]],
		sc15c => [[4,5]],
		rwin => [[4,5]],
		sc15d => [[4,6]],
		menu => [[4,6]],
		application => [[4,6]],
		sc11d => [[4,7]],
		rctrl => [[4,7]],
		sc053 => [[4,6]],
	);
	sub buttonPosition($)
	{
		return $buttonPositions{(lc shift)};
	}
	sub buttonPositionEnterMode
	{
		my $v = shift;
		return $buttonPositions{enterMode} unless defined $v;
		if ( $v == 0 ) {
			$buttonPositions{backspace} = [[0,14]];
			$buttonPositions{sc02b} = [[0,13]];
			$buttonPositions{enter} = [[2,12],[1,13]];
		} elsif ( $v == 1 ) {
			$buttonPositions{backspace} = [[0,13]];
			$buttonPositions{sc02b} = [[1,13]];
			$buttonPositions{enter} = [[2,12]];
		} elsif ( $v == 2 ) {
			$buttonPositions{backspace} = [[0,13]];
			$buttonPositions{sc02b} = [[2,12]];
			$buttonPositions{enter} = [[2,13],[1,13]];
		} else {
			die 'Bad enter mode: ' .$v;
		}
		$buttonPositions{sc01c} = $buttonPositions{enter};
		$buttonPositions{enterMode} = $v;
		return $v;
	}
	
	sub buttonWidth($$)
	{
		my $r = shift;
		my $c = shift;
		my $em = $buttonPositions{enterMode};
		if ( $em  == 0 ) {
			return 1   if ( $r == 0 && $c == 13 );
			return 0.8 if ( $r == 0 && $c == 14 );
			return 2.4 if ( $r == 2 && $c == 12 );
		} elsif ( $em  == 1 ) {
			return 2.4 if ( $r == 2 && $c == 12 );
		} elsif ( $em == 2 ) {
			return 1.15 if ( $r == 2 && $c == 13 );
		}
		return 2    if ( $r == 0 && $c == 13 );
		return 1.5  if ( $r == 1 && $c ==  0 );
		return 1.5  if ( $r == 1 && $c == 13 );
		return 1.9  if ( $r == 2 && $c ==  0 );
		return 1.25 if ( $r == 3 && $c ==  0 );
		return 3    if ( $r == 3 && $c == 12 );
		return 1.25 if ( $r == 4 && $c !=  3 );
		return 7.75 if ( $r == 4 && $c ==  3 );
		return 1;
	}
}

1;