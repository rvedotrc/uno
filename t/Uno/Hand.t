#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

use Test::More tests => 17;
use Test::Exception;

use_ok 'Uno::Hand';
use_ok 'Uno::Card';

sub get_card($) {
	my $t = shift;
	bless \$t, "Uno::Card";
}

my $hand = Uno::Hand->new;

is $hand->count, 0, "count 0";
is_deeply [$hand->cards], [], "no cards";
is $hand->score_value, 0, "score_value 0";
is $hand->as_string, "", "as_string empty";

my $r5 = get_card "r5";
my $ys = get_card "ys";
my $b0 = get_card "b0";
$hand->push($r5);
$hand->push($ys, $b0);

is $hand->count, 3, "count 3";
is @{[ $hand->cards ]}, 3, "3 cards";
is $hand->score_value, "25", "score_value 25";
is $hand->as_string, "$r5 $ys $b0", "as_string"; # fixme should be unordered

my $r9 = get_card "r9";
dies_ok { $hand->remove_card($r9) } "cannot remove a missing card";
lives_ok { $hand->remove_card($r5) } "can remove an existing card";
dies_ok { $hand->remove_card($r5) } "cannot remove a missing card";

is $hand->count, 2, "count 2";
is @{[ $hand->cards ]}, 2, "2 cards";
is $hand->score_value, "20", "score_value 20";
is $hand->as_string, "$ys $b0", "as_string"; # fixme should be unordered

# eof Hand.t
