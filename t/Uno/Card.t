#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

use Test::More tests => 11;

use_ok 'Uno::Card';

my @deck = Uno::CardFactory->deck;
is @deck, 4*(1+18+6)+4+4, "correct size deck";

my $c1 = $deck[1];
is "$c1", "r1", "red 1";
my @matching = grep { $_ eq $c1 } @deck;
is @matching, 2, "two red 1's";

my %penalties;
++$penalties{ $_->penalty_value } for @deck;
is_deeply \%penalties, { 4 => 4, 2 => 8, 0 => 96 }, "correct penalty_value";

my %scores;
++$scores{ $_->score_value } for @deck;
is_deeply \%scores, { 50 => 8, 20 => 24, (map { $_ => 8 } 1..9), 0 => 4 }, "correct score_value";

is((grep { $_->is_colour_change } @deck), 8, "eight colour changes");
is((grep { $_->is_miss_a_go } @deck), 8, "eight miss-a-go");
is((grep { $_->is_change_direction } @deck), 8, "eight direction changes");

my %colours;
++$colours{ $_->colour_of } for grep { not $_->is_colour_change } @deck;
is_deeply \%colours, { y=>25, r=>25, g=>25, b=>25 }, "colours";

my %symbols;
++$symbols{ $_->symbol_of } for grep { not $_->is_colour_change } @deck;
is_deeply \%symbols, { 0=>4, (map { $_=>8 } 1..9), s=>8, '>'=>8, '+'=>8 }, "symbols";

# eof Card.t
