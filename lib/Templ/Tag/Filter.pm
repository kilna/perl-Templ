package Templ::Tag::Filter;
use base 'Templ::Tag';

use strict;
use warnings;

use Carp qw(croak);

sub perl {
    my $self    = shift;
    my $content = defined($_[0]) ? shift : '';
    my $indent  = defined($_[0]) ? shift : '';
    my $append  = defined($_[0]) ? shift : '';

    my $expr = $self->filter . "( $content )";
    if ( $indent ne '' ) {
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
    return ($self->params)[0];
}

1;
