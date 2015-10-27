package Templ::Util;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK
    = qw(attempt quote unquote default indent undent number_lines headerize expand_isa);

use strict;
use warnings;

use Carp qw(croak);

# Run a block of code, return 0 if the code died, 1 if it didn't
sub attempt (&) {
    my $sub = shift;
    eval { $sub->(); };
    return $@ ? 0 : 1;
}

# Escapes a single-quoted string
sub quote ($) {
    my $str = shift;
    $str =~ s|\\|\\\\|gs;
    $str =~ s|'|\\'|gs;
    return $str;
}

# Escapes a single-quoted string
sub unquote ($) {
    my $str = shift;
    $str =~ s|\\\\|\\|gs;
    $str =~ s|\\'|'|gs;
    return $str;
}

# Returns the first defined value in a list, or a blank string if there are
# no defined values
sub default (@) {
    foreach (@_) { defined($_) && return $_; }
    return '';
}

sub undent ($) {
    no warnings 'uninitialized';
    return $_[0] if ( $_[0] !~ m/^(?:\r?\n)*([ \t]+)/ );
    my $i = $1;
    return join '', map { s/^\Q$i\E//; $_ } grep { $_ ne '' }
		split /(.*?\n)/, $_[0];
}

sub indent ($$) {
    no warnings 'uninitialized';
    return join '', map {"$_[0]$_"} grep { $_ ne '' } split /(.*?\n)/, $_[1];
}

sub headerize ($$) {
    no warnings 'uninitialized';
    return join '', map {"$_[0]$_\n"} split /\n/, $_[1];
}

sub number_lines ($) {
    no warnings 'uninitialized';
    my @lines = split /\n/, $_[0];
    my $format = '%' . length( scalar(@lines) . '' ) . "s: %s\n";
    return join '', map { sprintf( $format, ( $_ + 1 ), $lines[$_] ) }
		0 .. $#lines;
}

# Inspired by Class::ISA::self_and_super_path
sub expand_isa {
    no strict 'refs';
    my $seen = ref($_[0]) eq 'HASH' ? shift @_ : {};
    return
        map  { s/^::/main::/; $_ }
        grep { defined($_) && $_ ne '' }
        map  { $_, expand_isa( $seen, @{ $_ . '::ISA' } ) }
        grep { !$seen->{$_}++ }
        @_;
}

1;
