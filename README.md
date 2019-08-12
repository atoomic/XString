# NAME

XString - Isolated String helpers from B

# VERSION

version 0.001

# SYNOPSIS

```perl
#!perl

use strict;
use warnings;

use Test::More;

use XString;
use B;

is XString::cstring( q[a'string"with quotes] ), B::cstring( q[a'string"with quotes] ), q["a'string\"with quotes"];
is XString::perlstring( q[a'string"with quotes] ), B::perlstring( q[a'string"with quotes] ), q["a'string\"with quotes"];

done_testing;
```

# DESCRIPTION

XString provides the [B](https://metacpan.org/pod/B) string helpers in one isolated package.
Right now only [cstring](https://metacpan.org/pod/cstring) and [perlstring](https://metacpan.org/pod/perlstring) are available.

# FUNCTIONS

## cstring(STR)

Similar to B::cstring;
Returns a double-quote-surrounded escaped version of STR which can
be used as a string in C source code.

## perlstring(STR)

Similar to B::perlstring;
Returns a double-quote-surrounded escaped version of STR which can
be used as a string in Perl source code.

# AUTHOR

Nicolas R <atoomic@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
