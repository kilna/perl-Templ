package Templ::Tag::Comment;
use base 'Templ::Tag';

use strict;
use warnings;

sub perl {
    my $self    = shift;
    my $comment = shift;
    return join '', map {"# $_\n"} split /\n/, $comment;
}

1;
