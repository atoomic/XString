#!./perl

# Test edge cases: unusual SV types, boundary conditions, and
# string patterns that exercise the XS coercion paths.
# Every test compares XString output against B as the reference.

use warnings;
use strict;

use Test::More;

use XString ();
use B ();

# Helper: compare both cstring and perlstring against B
sub compare_both {
    my ($input, $desc) = @_;
    is(XString::cstring($input),    B::cstring($input),    "cstring: $desc");
    is(XString::perlstring($input), B::perlstring($input), "perlstring: $desc");
}

# --- SV type coercion ---
# XS calls SvPV() which triggers stringification for non-string SVs.
# Verify we match B for each SV type.

{
    # Integer (IV)
    my $iv = 42;
    compare_both($iv, "integer (IV)");
}

{
    # Negative integer
    my $neg = -1;
    compare_both($neg, "negative integer");
}

{
    # Float (NV)
    my $nv = 3.14159;
    compare_both($nv, "float (NV)");
}

{
    # Zero
    compare_both(0, "zero");
}

{
    # Dual-valued scalar (IV + PV)
    my $dual = 42;
    my $s = "$dual"; # force PV slot population
    compare_both($dual, "dual-valued scalar");
}

# --- Reference stringification ---

{
    my @arr = (1, 2, 3);
    compare_both(\@arr, "array reference");
}

{
    my %hash = (a => 1);
    compare_both(\%hash, "hash reference");
}

{
    my $code = sub { 1 };
    compare_both($code, "code reference");
}

{
    my $x = 42;
    compare_both(\$x, "scalar reference");
}

{
    my $re = qr/foo.bar/;
    compare_both($re, "regexp reference");
}

# --- Overloaded objects ---

{
    package OverloadStr;
    use overload '""' => sub { "hello\nworld" };
    sub new { bless {}, shift }
    package main;

    my $obj = OverloadStr->new;
    compare_both($obj, "overloaded stringification");
}

{
    # Object with special chars in overload result
    package OverloadSpecial;
    use overload '""' => sub { "\t\$foo \@bar\n" };
    sub new { bless {}, shift }
    package main;

    my $obj = OverloadSpecial->new;
    compare_both($obj, "overloaded with special chars");
}

# --- Blessed reference without overload ---

{
    package PlainObj;
    sub new { bless { x => 1 }, shift }
    package main;

    my $obj = PlainObj->new;
    compare_both($obj, "blessed ref without overload");
}

# --- Boundary strings ---

{
    # All 256 byte values in a single string
    my $all = join "", map { chr($_) } 0 .. 255;
    compare_both($all, "all 256 byte values");
}

{
    # Only high-bit bytes (128..255)
    my $high = join "", map { chr($_) } 128 .. 255;
    compare_both($high, "high-bit bytes only (128..255)");
}

{
    # Only control characters (0..31)
    my $ctrl = join "", map { chr($_) } 0 .. 31;
    compare_both($ctrl, "all control characters (0..31)");
}

{
    # Large string (100K)
    my $big = "A" x 100_000;
    compare_both($big, "large string (100K printable)");
}

{
    # Large string with escapes needed
    my $big_esc = ("\n" x 10_000);
    compare_both($big_esc, "large string (10K newlines)");
}

# --- NUL byte patterns ---

{
    compare_both("\0", "single NUL byte");
}

{
    compare_both("\0\0\0\0\0", "multiple NUL bytes");
}

{
    compare_both("abc\0def\0ghi", "NUL bytes between printable text");
}

{
    compare_both("\0ABC\0", "NUL bytes at boundaries");
}

# --- Interpolation characters ($ and @) ---
# cstring should NOT escape these; perlstring MUST escape them

{
    my $interp = q{$foo @bar};
    compare_both($interp, 'dollar and at-sign');
}

{
    my $complex = q{$hash{key} @array[0]};
    compare_both($complex, 'dollar/at with subscripts');
}

{
    # UTF-8 string with interpolation chars
    my $utf_interp = "\x{263A} \$foo \@bar";
    utf8::upgrade($utf_interp);
    compare_both($utf_interp, 'UTF-8 string with dollar/at');
}

# --- Whitespace and control char combinations ---

{
    my $ws = "\t\n\r\f\a\b";
    compare_both($ws, "standard control chars");
}

{
    # Vertical tab: \v in cstring, octal in perlstring
    my $vt = chr(11);
    compare_both($vt, "vertical tab");
}

{
    # ESC character (0x1B)
    compare_both(chr(0x1B), "ESC character");
}

{
    # DEL character (0x7F)
    compare_both(chr(0x7F), "DEL character");
}

# --- Quote and backslash patterns ---

{
    compare_both('"', "double quote alone");
}

{
    compare_both('\\', "backslash alone");
}

{
    compare_both('""', "two double quotes");
}

{
    compare_both('\\\\', "two backslashes");
}

{
    compare_both('"\\', "quote then backslash");
}

{
    compare_both('\\"', "backslash then quote");
}

# --- UTF-8 edge cases ---

{
    # Upgraded empty string
    my $empty = "";
    utf8::upgrade($empty);
    compare_both($empty, "upgraded empty string");
}

{
    # Upgraded string that is pure ASCII
    my $ascii = "hello";
    utf8::upgrade($ascii);
    compare_both($ascii, "upgraded pure ASCII");
}

{
    # BOM character
    compare_both("\x{feff}", "BOM (U+FEFF)");
}

{
    # Replacement character
    compare_both("\x{fffd}", "replacement char (U+FFFD)");
}

{
    # Last valid Unicode codepoint
    compare_both(chr(0x10FFFF), "last Unicode codepoint (U+10FFFF)");
}

{
    # Mixed ASCII + multi-byte with embedded controls
    my $mix = "A\x{100}\n\x{1F600}\t\x{E9}";
    utf8::upgrade($mix);
    compare_both($mix, "mixed ASCII + multi-byte + controls (UTF-8)");
}

done_testing();
