#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

use Test::More tests => 7;
use Test::Exception;

use_ok 'Uno::Table';
use_ok 'Uno::Card';

my @deck = Uno::CardFactory->deck;
my $table = Uno::Table->new({ deck => \@deck });

is $table->top, undef, "nothing initially discarded";

my @ten = map { $table->next_card } 1..10;

$table->discard($ten[7]);
is $table->top, $ten[7], "discard";
$table->discard($ten[3]);
is $table->top, $ten[3], "discard";
$table->discard($ten[0]);
is $table->top, $ten[0], "discard";

my $n = 0;
for my $x (1..200) {
	my $c = eval { $table->next_card } or last;
	++$n;
	# print "# $n got $c\n";
}

# Off-by-one is because we must always leave one card on the table
is $n, 100, "101 cards were left on the table";

# eof Table.t
