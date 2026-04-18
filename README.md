# NAME

XString - Isolated String helpers from B

# VERSION

version 0.006

# SYNOPSIS

```perl
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
```

# DESCRIPTION

XString provides the [B](https://metacpan.org/pod/B) string helpers in one isolated package.
Right now only [cstring](https://metacpan.org/pod/cstring) and [perlstring](https://metacpan.org/pod/perlstring) are available.

[![CI](https://github.com/atoomic/XString/actions/workflows/ci.yml/badge.svg)](https://github.com/atoomic/XString/actions/workflows/ci.yml)

# FUNCTIONS

## cstring(STR)

Similar to B::cstring;
Returns a double-quote-surrounded escaped version of STR which can
be used as a string in C source code.

## perlstring(STR)

Similar to B::perlstring;
Returns a double-quote-surrounded escaped version of STR which can
be used as a string in Perl source code.

# AI POLICY

This project uses AI tools to assist development. Humans review and approve every change before it is merged. See [AI\_POLICY.md](AI_POLICY.md) for details.

# AUTHOR

Nicolas R <atoomic@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
