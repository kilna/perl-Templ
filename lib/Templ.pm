package Templ;

use strict;
use warnings;

use Scope::Upper qw(localize UP);
use File::Find;
use File::Spec::Functions qw(catdir abs2rel curdir splitdir);
use Carp qw(croak);

our $VERSION = "0.01_01";
$VERSION = eval $VERSION;

our $spec_class;
BEGIN {
    $Templ::spec_class = 'Templ::Spec::Basic';
    # Somewhat inspired by Module::Find...
    # Perform a "require MODULE;" for all Templ::* modules
    foreach my $dir ( grep { -d } map { catdir($_,'Templ') } @INC ) {
        my $wanted = sub {
            return unless -r;
            return if abs2rel($_,$dir) !~ m/^(.*)\.pm$/;
            my $module = join( '::', 'Templ', splitdir($1) );
            return unless $module =~ m/^(\w+::)*\w+$/;
            return if $Templ::loaded{$module}++;
            eval "require $module;";
            $@ && croak $@;
        };
        # Find the perl modules under thes dirs and "require" them
        find( { wanted => $wanted, no_chdir => 1, follow => 1 }, $dir );
    }
}

sub templ        ($;$)  { $spec_class->templ( @_ )        }
sub templ_method ($$;$) { $spec_class->templ_method( @_ ) }
sub templ_sub    ($$;$) { $spec_class->templ_sub( @_ )    }

sub templ_spec (;$$) {
    return $spec_class unless scalar @_;
    my $new_spec_class = shift;
    my $context = shift || UP;
    if ( not Templ::Spec::_subclass_loaded($new_spec_class) ) {
        if ( $Templ::loaded{'Templ::Spec::'.$new_spec_class} ) {
            $new_spec_class = 'Templ::Spec::'.$new_spec_class;
        }
        Templ::Spec::_load_subclass($new_spec_class);
    }
    localize '$Templ::spec_class', $new_spec_class, $context;
    return $new_spec_class;
}

sub import {
    my $class = shift;
    my %valid_exports = map { $_ => 1 } qw(templ templ_method templ_sub templ_spec);
    my @export = ();
    while (scalar @_) {
        my $item = shift @_;
        if ($item eq '-spec') {
            templ_spec( shift(@_), UP );
            next;
        }
        if (not exists $valid_exports{$item}) {
            croak "Unknown function: $item";
        }
        push @export, $item;
    }
    unless (scalar @export) {
        @export = keys %valid_exports;
    }
    foreach ( qw(templ templ_method templ_sub templ_spec) ) {
        no strict 'refs';
        *{caller().'::'.$_} = \*{$_};
    }
}

1;
