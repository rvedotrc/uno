#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

package Uno::Player;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( name hand ));

use overload
	'""' => sub { $_[0]->name },
	;

1;
# eof Player.pm
