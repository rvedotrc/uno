#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;
use integer;

select STDERR; $| = 1;
select STDOUT; $| = 1;

{
	my @deck = whole_deck();
	use List::Util qw( shuffle );
	@deck = shuffle(@deck);

	my @players = (
		{ name => "Alice" },
		{ name => "Bob" },
		{ name => "Charles" },
		{ name => "Diana" },
		{ name => "Edward" },
		# { name => "Fiona" },
		# { name => "Gary" },
		# { name => "Helen" },
	);

	my $turns = 0;

	# state of play:

	# - top card on deck
	my @discards;

	# - uncollected penalties
	my $uncollected_penalties = 0;

	my $miss_a_go = 0;

	# - nominated colour
	my $nominated_colour = undef;

	# - players' hands
	# @players

	# - direction of play
	my $direction = +1;

	# - whose turn
	my $to_play = int rand @players;
	print "$players[$to_play]{name} deals\n";

	for (1..7) {
		# In theory should deal from $to_play+1 round to $to_play... but makes
		# no odds overall
		for my $player (@players) {
			my $card = next_card();
			# print "$card -> $player->{name}\n";
			push @{ $player->{hand} }, $card;
		}
	}

	# The dealer effectively plays the first card
	{
		my $card = next_card();
		print "Dealer turns over $card\n";
		play_card($card);
	}

	sub play_card
	{
		my ($card, $say_colour) = @_;

		# By this point we know that the card play is allowed
		# and that the card has been removed from the player's hand, etc
		# Change state accordingly
		push @discards, $card;

		if (is_colour_change($card) and $say_colour) {
			# print "$players[$to_play]{name} nominates $say_colour\n";
			$nominated_colour = $say_colour;
		}

		if (my $p = penalty_value($card)) {
			$uncollected_penalties += $p;
			print "+$uncollected_penalties uncollected penalties\n";
		}

		if (is_change_direction($card)) {
			$direction = -$direction;
			print "Now playing ";
			print($direction == 1 ? "to the left" : "to the right");
			print "\n";
		}
		
		if (is_miss_a_go($card)) {
			++$miss_a_go;
			print "Next player will miss a go\n";
		}
	}

	sub find_playable_cards {
		my @cards = @_;
		my $top = $discards[-1];

		my @map = map { [ $_,0] } @cards;

		if ($uncollected_penalties) {
			# If there are uncollected penalties then the top card must be a
			# penalty of that type
			my $value = penalty_value($top);
			# Can only play penalties that match
			for my $c (@map) {
				$c->[1] = 1 if penalty_value($c->[0]) == $value;
			}
			return @map;
		}

		# No penalties, so work out what else (other than colour change / +4s)
		# are playable

		for my $c (@map) {
			my $card = $c->[0];

			next if is_colour_change($card);

			if (is_colour_change($top)) {
				# Can't match on symbol, only on colour
				$c->[1] = 1 if not $nominated_colour or $nominated_colour eq colour_of($card);
			} else {
				# Can match on colour or symbol
				$c->[1] = 1 if colour_of($card) eq colour_of($top);
				$c->[1] = 1 if symbol_of($card) eq symbol_of($top);
			}
		}

		if (not grep { $_->[1] } @map) {
			# Nothing else playable, so +4s are allowed
			for my $c (@map) {
				my $card = $c->[0];
				$c->[1] = 1 if is_colour_change($card) and penalty_value($card);
			}
		}

		# Plain colour changes are allowed
		{
			for my $c (@map) {
				my $card = $c->[0];
				$c->[1] = 1 if is_colour_change($card) and not penalty_value($card);
			}
		}

		return @map;
	}

	sub next_turn {
		my $top = $discards[-1];

		for (;;) {
			$to_play = ($to_play + @players + $direction) % @players;
			if ($miss_a_go) {
				print "$players[$to_play]{name} misses a go\n";
				--$miss_a_go;
				next;
			}
			last;
		}

		print "$players[$to_play]{name} to play\n";

		# dump_all();
	}

	sub next_card {
		# printf "next_card called, deck=%d, discards=%d\n", 0+@deck, 0+@discards;
		return pop @deck if @deck;
		if (@discards > 1) {
			my $top = pop @discards;
			@deck = reverse @discards;
			@discards = $top;
			return pop @deck;
		}
		die "next_card called with no cards";
	}

	sub dump_all {
		printf "Deck (%d): %s\n", 0+@deck, join(" ", @deck);
		printf "Discards (%d): %s\n", 0+@discards, join(" ", @discards);
		for my $who (@players) {
			printf "%s (%d): %s\n", $who->{name}, hand_value($who->{hand}), join(" ", @{ $who->{hand} });
		}
		print "uncollected_penalties: $uncollected_penalties\n";
		print "direction: $direction\n";
		print "to_play: $to_play\n";

		my $n = 0;
		$n += @deck;
		$n += @discards;
		$n += @{ $_->{hand} } for @players;
		die "Cards missing! (found $n)" unless $n == 108;
	}

	sub hand_value {
		my $hand = shift;
		my $t = 0;
		$t += score_value($_) for @$hand;
		return $t;
	}

	for (;;) {
		next_turn();
		++$turns;
		print "=" x 80;
		print "\n";
		print "Turn #$turns\n";
		my $who = $players[$to_play];

		my $h = $who->{hand};
		my @playable = find_playable_cards(@$h);

		print "$who->{name}'s hand:\n";
		print "$_->[0] " for @playable;
		print "\n";
		printf "%s ", ("  ", "--")[$_->[1]] for @playable;
		print "\n";

		my ($play, $col);
		if (grep { $_->[1] } @playable) {
			my $can_pass = (not $uncollected_penalties);
			($play, $col) = pick_card_to_play(\@playable, $can_pass);
		} else  {
			# Nothing playable: pick up (penalties or 1)
		}

		if (not defined $play) {
			my $n = $uncollected_penalties || 1;
			my @c = map { next_card() } 1..$n;
			print "$who->{name} picks up";
			print " $_" for @c;
			print "\n";
			push @$h, @c;
			$uncollected_penalties = 0;
			next;
		}

		# Otherwise, we have chosen a card to play
		if (is_colour_change($play) and not $col) {
			die "colour change played with no colour nominated";
		}

		{
			my $removed;
			for (0..$#$h) {
				$h->[$_] eq $play or next;
				splice(@$h, $_, 1);
				++$removed;
				last;
			}
			$removed or die "Can't play $play, it's not in your hand";
		}

		print "$who->{name} plays $play";
		print " and nominates $col" if $col;
		print " and declares 'Uno'" if @$h == 1;
		print "\n";

		play_card($play, $col);

		if (not @$h) {
			print "$who->{name} is out\n";
			last;
		}
	}

	print "Game over\n";

	for my $who (@players) {
		my $h = $who->{hand};
		my $t = hand_value($h);
		printf "%s scores %d (%s)\n", $who->{name}, $t, join(" ", @$h);
	}

	# dump_all();
}

exit;

sub whole_deck
{
	my @col = (
		0,
		(1..9, qw( > + s ))x2,
	);
	return (
		(map { my $c = $_; map { $c.$_ } @col } qw( r g y b )),
		(("**") x 4),
		(("+4") x 4),
	);
}

sub penalty_value
{
	local $_ = shift;
	return 4 if $_ eq "+4";
	return 2 if /\+$/;
	return 0;
}

sub score_value
{
	local $_ = shift;
	return 50 if $_ eq "**" or $_ eq "+4";
	/(\d)$/ ? $1 : 20;
}

sub is_colour_change
{
	local $_ = shift;
	$_ eq "**" or $_ eq "+4";
}

sub is_miss_a_go { $_[0] =~ /s$/ }
sub is_change_direction { $_[0] =~ />$/ }

sub symbol_of { substr($_[0], 1, 1) }
sub colour_of { substr($_[0], 0, 1) }

sub pick_card_to_play {
	my @playable = @{ shift() };
	my $can_pass = shift;

	# Something is playable
	# TODO improve this :-)
	my $play;
	for (shuffle(0..$#playable)) {
		$playable[$_][1] or next;
		$play = $playable[$_][0];
		splice(@playable, $_, 1);
		last;
	}

	# TODO improve this
	my $col;
	$col = "r" if is_colour_change($play);

	return ($play, $col);
}

1;
# eof Game.pm
