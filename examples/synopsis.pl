#!perl

use strict;
use warnings;

use XString;

# C-style string escaping (for embedding in C source code)
my $c = XString::cstring("Hello\tWorld\n");
print "cstring:    $c\n";    # "Hello\tWorld\n"

# Perl-style string escaping (for embedding in Perl source code)
my $p = XString::perlstring("Hello\tWorld\n");
print "perlstring: $p\n";    # "Hello\tWorld\n"

# Both handle special characters, control codes, and Unicode
my $special = XString::perlstring("Price: \$9.99 \@discount");
print "escaped:    $special\n";    # "Price: \$9.99 \@discount"
