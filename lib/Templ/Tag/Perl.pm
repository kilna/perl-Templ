package Templ::Tag::Perl;
use base 'Templ::Tag';

use strict;
use warnings;

sub perl {
    my $self    = shift;
    my $content = shift;

    return $content;
}

1;
