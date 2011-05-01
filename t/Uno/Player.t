#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;

use Test::More tests => 5;

use_ok 'Uno::Hand';
use_ok 'Uno::Player';

my $h = Uno::Hand->new;
my $p = Uno::Player->new({ name => "Bob", hand => $h });

is $p->name, "Bob", "name";
is $p->hand, $h, "hand";
is "$p", "Bob", "stringification";

# eof Player.t
