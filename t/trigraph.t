#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test::More;

use XString ();

use B ();

# Trigraph sequences: the C preprocessor interprets ??X as special characters.
# cstring() must escape the first '?' to prevent trigraph interpretation.
# perlstring() should pass them through unescaped (no trigraphs in Perl).
my @trigraph_strings = (
    q[??=],        # trigraph for #
    q[??/],        # trigraph for backslash
    q[??'],        # trigraph for ^
    q[??(],        # trigraph for [
    q[??)],        # trigraph for ]
    q[??!],        # trigraph for |
    q[??<],        # trigraph for {
    q[??>],        # trigraph for }
    q[??-],        # trigraph for ~
    q[a??/b],      # trigraph embedded in a word
    q[??=??=],     # consecutive trigraphs
    q[hello??!world],  # trigraph in the middle of text
    q[??],         # lone double question mark (len < 3, no trigraph)
    q[?],          # single question mark (no escaping needed)
);

{
    #note "testing cstring with trigraph sequences";
    foreach my $str ( @trigraph_strings ) {
        my $expected = B::cstring( $str );
        is XString::cstring( $str ), $expected, "cstring trigraph: $expected";
    }
}

{
    #note "testing perlstring with trigraph sequences";
    foreach my $str ( @trigraph_strings ) {
        my $expected = B::perlstring( $str );
        is XString::perlstring( $str ), $expected, "perlstring trigraph: $expected";
    }
}

done_testing();
