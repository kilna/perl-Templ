package Templ::Header;

use strict;
use warnings;

use Carp qw(carp croak);

use overload '""' => sub { my $self = shift; $$self };

sub add {
    my $class = shift;
    if ( not defined $class || ref $class || $class !~ m/^(\w+\:\:)*\w+$/ ) {
        croak "Can only be called as ".__PACKAGE__."->new";
    }
    my $self = \($_[0].'');
    bless $self, $class;
    my $target_class = caller;
    no strict 'refs';
    no warnings 'once';
    push @{ $target_class.'::TEMPL_HEADERS' }, $self;
    return $self;
}

*new = *add;

1;
