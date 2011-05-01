#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

package Uno::CardFactory;

sub bless_as { "Uno::Card" }

sub deck
{
	my ($class) = @_;

	my @col = (
		0,
		(1..9, qw( > + s ))x2,
	);

	my @deck = (
		(map { my $c = $_; map { $c.$_ } @col } qw( r g y b )),
		(("**") x 4),
		(("+4") x 4),
	);

	my $c = $class->bless_as;
	return map {
		bless \"$_", $c
	} @deck;
}

package Uno::Card;

use overload
	'""'	=> sub { ${ $_[0] } },
	'eq'	=> sub { ${$_[0]} eq ${$_[1]} },
	;

sub penalty_value
{
	local $_ = ${ shift() };
	return 4 if $_ eq "+4";
	return 2 if /\+$/;
	return 0;
}

sub score_value
{
	local $_ = ${ shift() };
	return 50 if $_ eq "**" or $_ eq "+4";
	/(\d)$/ ? $1 : 20;
}

sub is_colour_change
{
	local $_ = ${ shift() };
	$_ eq "**" or $_ eq "+4";
}

sub is_miss_a_go { ${$_[0]} =~ /s$/ }
sub is_change_direction { ${$_[0]} =~ />$/ }

sub symbol_of { substr(${$_[0]}, 1, 1) }
sub colour_of { substr(${$_[0]}, 0, 1) }

1;
# eof Card.pm
