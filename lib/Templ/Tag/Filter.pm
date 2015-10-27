package Templ::Tag::Filter;
use base 'Templ::Tag';

use strict;
use warnings;

use Templ::Util qw(default);
use Carp qw(croak);

sub perl {
    my $self    = shift;
    my $content = shift;
    my $indent  = shift;
    my $append  = shift;

    my $expr = $self->filter . "( $content )";
    if ( default($indent) ne '' ) {
        $expr = "indent( '$indent', $expr )";
    }

    return "$append$expr;\n";
}

sub check {
    my $self = shift;
    $self->SUPER::check();
    if ( $self->filter() !~ m/^\w+$/ ) {
        croak "Missing or malformed 'filter' for " . __PACKAGE__ . " object";
    }
}

sub filter {
    my $self = shift;
    return default $self->{'filter'};
}

1;
