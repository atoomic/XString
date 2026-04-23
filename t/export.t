#!./perl

# Test that cstring and perlstring can be imported via Exporter.
# Verify imported functions produce identical output to fully-qualified calls.

use warnings;
use strict;

use Test::More;

# Import both functions
use XString qw(cstring perlstring);

# Verify they are available in our namespace
ok(defined &cstring,    'cstring imported');
ok(defined &perlstring, 'perlstring imported');

# Verify imported functions produce same results as fully-qualified
my @samples = (
    "hello",
    "with\"quotes",
    "with\nnewline",
    "\t\r\n",
    chr(0),
    chr(255),
);

for my $s (@samples) {
    is(cstring($s),    XString::cstring($s),    "cstring export matches: " . XString::cstring($s));
    is(perlstring($s), XString::perlstring($s), "perlstring export matches: " . XString::perlstring($s));
}

# Verify undef handling
is(cstring(undef),    XString::cstring(undef),    'cstring export: undef');
is(perlstring(undef), XString::perlstring(undef), 'perlstring export: undef');

done_testing();
