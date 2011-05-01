#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

package Uno::Table;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( deck discards ));

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->deck([])     unless $self->deck;
	$self->discards([]) unless $self->discards;
	$self;
}

sub next_card
{
	my ($self) = @_;
	my $deck = $self->deck;
	my $discards = $self->discards;
	# printf "next_card called, deck=%d, discards=%d\n", 0+@$deck, 0+@$discards;
	return pop @$deck if @$deck;
	if (@$discards > 1) {
		my $top = pop @$discards;
		@$deck = reverse @$discards;
		@$discards = $top;
		return pop @$deck;
	}
	die "next_card called with no cards";
}

sub discard
{
	my ($self, $card) = @_;
	push @{ $self->discards }, $card;
}

sub top
{
	my ($self) = @_;
	$self->discards->[-1];
}

1;
# eof Table.pm
