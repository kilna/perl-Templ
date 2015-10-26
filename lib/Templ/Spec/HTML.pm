package Templ::Spec::HTML;
use base 'Templ::Spec::XML'; 

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(uri_escape);

use strict;
use warnings;

use Templ (); # Loads all modules, but doesn't import anything

add Templ::Header 'use Templ::Spec::HTML;';
add Templ::Tag::Filter '%' => 'uri_escape';

my $url_regex = qr/[^A-Za-z0-9_\.~-]/;;
my %url_charmap = (
    map { chr($_) => sprintf( '%%%02X', $_ ); }
    grep { chr($_) =~ m/^$url_regex$/ }
    0 .. 255
);

sub uri_escape {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s/($url_regex)/$url_charmap{$1}/gs;
    $str =~ s/\%20/+/gs;
    return $str;
}

1;
