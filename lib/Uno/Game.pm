#!/usr/bin/perl
# vi: set ts=4 sw=4 :

use warnings;
use strict;
use integer;

use Uno::Card;
use Uno::Hand;
use Uno::Table;
use Uno::Player;

package Uno::Game;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(
	players
	turns
	table
	uncollected_penalties
	miss_a_go
	nominated_colour
	direction
	to_play
	starting_card_count
	game_over
));

# TODO game variations to build in:

# Forgetting to declare 'Uno'

# If you're not missing your turn, and there are no uncollected penalties, and
# you don't have any matching coloured cards, and you have both a +4 and a
# colour change, are you allowed to play the +4?  Currently: yes.

# Can you opt to pick up, even if there is a card you can play?  Currently:
# yes.

# Different types of decks

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	my %defaults = (
		players => [],
		turns => 0,
		table => sub {
			my @deck = Uno::CardFactory->deck;
			use List::Util qw( shuffle );
			@deck = shuffle(@deck);
			Uno::Table->new({ deck => \@deck });
		},
		uncollected_penalties => 0,
		miss_a_go => 0,
		nominated_colour => undef,
		direction => +1,
		starting_card_count => 7,
		game_over => 0,
	);

	while (my ($k, $v) = each %defaults) {
		next if defined $self->$k;
		$v = &$v if ref($v) eq "CODE";
		$self->$k($v);
	}

	@{ $self->players } or die "Need at least one player";

	$self->to_play(int rand @{ $self->players })
		unless defined $self->to_play;

	# Deal
	$self->debug($self->players->[$self->to_play]." deals");

	# In theory should deal from $to_play+1 round to $to_play... but makes
	# no odds overall
	for my $player (@{ $self->players }) {
		next if $player->hand;

		my $hand = Uno::Hand->new;

		for my $n (1 .. $self->starting_card_count) {
			my $card = $self->table->next_card;
			$self->debug("Dealt $card to $player");
			$hand->push($card);
		}

		$player->hand($hand);
	}

	# Sanity check, every player should have at least one card
	for my $player (@{ $self->players }) {
		$player->hand->count
			or die "$player has no cards!";
	}

	# The dealer effectively plays the first card
	{
		my $card = $self->table->next_card();
		$self->debug("Dealer turns over $card");
		$self->play_card($card);
	}

	$self;
}

sub debug {
	my ($self, $msg) = @_;
	print "DEBUG: $msg\n";
}

sub play_card {
	my ($self, $card, $say_colour) = @_;

	# By this point we know that the card play is allowed
	# and that the card has been removed from the player's hand, etc
	# Change state accordingly
	$self->table->discard($card);

	if ($card->is_colour_change and $say_colour) {
		$self->nominated_colour($say_colour);
	}

	if (my $p = $card->penalty_value) {
		$self->uncollected_penalties($self->uncollected_penalties + $p);
		$self->debug("+".$self->uncollected_penalties." uncollected penalties");
	}

	if ($card->is_change_direction) {
		$self->direction(0 - $self->direction);
		my $dir = ($self->direction == 1 ? "left" : "right");
		$self->debug("Now playing to the $dir");
	}
	
	if ($card->is_miss_a_go) {
		$self->miss_a_go($self->miss_a_go + 1);
		$self->debug("Next player will miss a go");
	}
}

sub find_playable_cards {
	my ($self, $cards) = @_;

	my $top = $self->table->top;

	my @map = map { [ $_,0 ] } @$cards;

	if ($self->uncollected_penalties) {
		# If there are uncollected penalties then the top card must be a
		# penalty of that type
		my $value = $top->penalty_value;
		# Can only play penalties that match
		for my $c (@map) {
			$c->[1] = 1 if $c->[0]->penalty_value == $value;
		}
		return \@map;
	}

	# No penalties, so work out what else (other than colour change / +4s)
	# are playable

	for my $c (@map) {
		my $card = $c->[0];

		next if $card->is_colour_change;

		if ($top->is_colour_change) {
			# Can't match on symbol, only on colour
			$c->[1] = 1 if not $self->nominated_colour or $self->nominated_colour eq $card->colour_of;
		} else {
			# Can match on colour or symbol
			$c->[1] = 1 if $card->colour_of eq $top->colour_of;
			$c->[1] = 1 if $card->symbol_of eq $top->symbol_of;
		}
	}

	if (not grep { $_->[1] } @map) {
		# Nothing else playable, so +4s are allowed
		for my $c (@map) {
			my $card = $c->[0];
			$c->[1] = 1 if $card->is_colour_change and $card->penalty_value;
		}
	}

	# Plain colour changes are allowed
	{
		for my $c (@map) {
			my $card = $c->[0];
			$c->[1] = 1 if $card->is_colour_change and not $card->penalty_value;
		}
	}

	return \@map;
}

sub next_turn {
	my ($self) = @_;

	my $n_players = @{ $self->players };

	for (;;) {
		$self->to_play(( $self->to_play + $n_players + $self->direction) % $n_players);
		if ($self->miss_a_go) {
			$self->debug($self->players->[$self->to_play]." misses a go");
			$self->miss_a_go( $self->miss_a_go - 1 );
			next;
		}
		last;
	}

	$self->debug($self->players->[$self->to_play]." to play");

	# $self->dump_all;
}

sub dump_all {
	my ($self) = @_;

	$self->debug("dump_all of $self:");

	my $deck = $self->table->deck;
	my $discards = $self->table->discards;
	$self->debug(sprintf "Deck (%d): %s", 0+@$deck, join(" ", @$deck));
	$self->debug(sprintf "Discards (%d): %s", 0+@$discards, join(" ", @$discards));

	$self->debug("  players:");
	for my $who (@{ $self->players }) {
		my $h = $who->hand;
		$self->debug(sprintf "    %s (%d): %s", $who, $h->score_value, $h->as_string);
	}

	$self->debug("  uncollected_penalties: ".$self->uncollected_penalties);
	$self->debug("  direction: ".$self->direction);
	$self->debug("  to_play: ".$self->players->[$self->to_play]);

	my $n = 0;
	$n += @{ $self->table->deck };
	$n += @{ $self->table->discards };
	$n += $_->hand->count for @{ $self->players };
	$self->debug("  accounted for $n cards");
	die "Cards missing! (found $n)" unless $n == 108;

	$self->debug("end of dump_all");
}

sub play_next_turn_with_callback {
	my ($self, $player_callback) = @_;

	$self->next_turn;

	$self->turns($self->turns + 1);
	$self->debug("=" x 80);
	$self->debug("Turn #".$self->turns);
	my $who = $self->players->[$self->to_play];

	my $h = $who->hand;
	my $playable = $self->find_playable_cards([ $h->cards ]);

	$self->debug("$who\'s hand: ".join(" ", map {
		$_->[1]
		? ":$_->[0]:"
		: "$_->[0]"
	} @$playable));

	my ($play, $col);
	if (grep { $_->[1] } @$playable) {
		my $can_pass = ($self->uncollected_penalties == 0);
		($play, $col) = &$player_callback($playable, $can_pass);
	} else  {
		# Nothing playable: pick up (penalties or 1)
	}

	if (not defined $play) {
		my $n = $self->uncollected_penalties || 1;
		my @c = map { $self->table->next_card() } 1..$n;
		local $" = " ";
		$self->debug("$who picks up @c");
		$h->push(@c);
		$self->uncollected_penalties(0);
		return;
	}

	# Otherwise, we have chosen a card to play
	if ($play->is_colour_change and not $col) {
		die "colour change played with no colour nominated";
	}

	# TODO check that the card chosen is playable

	$h->remove_card($play);

	my $m = "$who plays $play";
	$m .= " and nominates $col" if $col;
	$m .= " and declares 'Uno'" if $h->count == 1;
	$self->debug($m);

	$self->play_card($play, $col);

	if (not $h->count) {
		$self->debug("$who is out");
		$self->game_over(1);
	}
}

sub end_of_game {
	my ($self) = @_;
	$self->debug("=" x 80);
	$self->debug("Game over");

	for my $who (@{ $self->players }) {
		my $h = $who->hand;
		$self->debug(sprintf "%s scores %d (%s)", $who, $h->score_value, join(" ", $h->cards)||'no cards');
	}

	# $self->dump_all;
}

1;
# eof Game.pm
