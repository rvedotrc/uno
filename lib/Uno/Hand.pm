#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

package Uno::Hand;

sub new
{
	my ($class) = @_;
	bless [], $class;
}

sub count
{
	return scalar @{ shift() };
}

sub cards
{
	return @{ shift() };
}

sub score_value
{
	my ($self) = @_;
	my $t = 0;
	$t += $_->score_value for $self->cards;
	return $t;
}

sub as_string
{
	my ($self) = @_;
	return join(" ", $self->cards);
}

sub push
{
	my ($self, @cards) = @_;
	push @$self, @cards;
}

sub remove_card
{
	my ($self, $card) = @_;
	my $removed;
	for (0..$#$self)
	{
		$self->[$_] eq $card or next;
		splice(@$self, $_, 1);
		++$removed;
		last;
	}
	$removed or die "Asked to remove card $card that's not in hand $self";
}

1;
# eof Hand.pm
