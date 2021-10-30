#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

use Config;
use File::Spec;
use lib qw( ../lib lib );
use B::Keywords ':all';

# Translate control characters into ^A format
# Leave others alone.
my @control_map = (undef, "A".."Z");
sub _map_control_char {
    my $char = shift;
    my $ord = ord $char;

    return "^".$control_map[$ord] if $ord <= 26;
    return $char;
}

# Test everything in keywords.h is covered.
{
    my $keywords = File::Spec->catfile( $Config{archlibexp}, 'CORE', 'keywords.h' );
    open FH, "< $keywords\0" or die "Can't open $keywords: $!";
    local $/;
    chomp( my @keywords = <FH> =~ /^\#define \s+ KEY_(\S+) /xmsg );
    close FH;
    my $usedevel = $Config{usedevel};

    my %covered = map { $_ => 1 } @Symbols, @Barewords;
    note "check if all keywords.h have \@Symbols or \@Barewords";
    for my $keyword (@keywords) {
        if (!$covered{$keyword} && $usedevel) {
            ok $covered{$keyword}, "TODO keyword: $keyword (old blead version, wait for the release)";
        } else {
            ok $covered{$keyword}, "keyword: $keyword";
        }
    }

    note "reverse: check if all \@Symbols and \@Barewords are in keywords.h";
    my %keyword = map { $_ => 1 } @keywords;
    for my $key (@Barewords, @Functions) {
        if ($key =~ /^-/) { # skip file test ops
            note "not in keyword.h: $key";
        }
        elsif (!$keyword{$key} && $usedevel) {
            ok $keyword{$key}, "TODO keyword.h: $key (old blead version, wait for the release)";
        } else {
            ok $keyword{$key}, "keyword.h: $key";
        }
    }
}

# Test all the single character globals in main
{
    my @globals = map  { _map_control_char($_) }
                  grep { length $_ == 1 and /\W/ }
                       keys %main::;

    my %symbols = map { s/^.//; $_ => 1 } (@Scalars, @Arrays, @Hashes);
    note "check if all single-character \@Scalars, \@Arrays, \@Hashes are as globals in \%main::";
    for my $global (@globals) {
        ok $symbols{$global}, "global: $global";
    }

    #my %globals = map { $_ => 1 } @globals;
    note "the reverse is not true as most globals are auto-created";
    #for my $sym (grep { length $_ == 1 } keys %symbols) {
    #   ok $globals{$sym}, "\%main:: $sym";
    #}
}

# Cannot test all the other globals in main. They are mostly created on-the-fly.
if (0) {
    my %globals = map  { _map_control_char($_) => 1 }
                  grep { length $_ > 1 && $_ !~ /^_</ && $_ !~ /::$/ }
                       keys %main::;

    require English;
    English->import;
    note "check if all multi-character \@Scalars, \@Arrays, \@Hashes are as globals in \%main::";
    my %symbols = map { s/^[\$\%\@]//; $_ => 1 } (@Scalars, @Arrays, @Hashes);
    for my $sym (grep { length $_ > 1 } keys %symbols) {
        ok $globals{$sym}, "\%main:: $sym";
    }
    # and the reverse is troubled by namespace pollution. %main:: contains B, Test, ...
}
