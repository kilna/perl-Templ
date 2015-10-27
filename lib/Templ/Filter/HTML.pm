
package Templ::Filter::HTML;

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(encode_html encode_entities uri_escape);

use strict;
use warnings;
no warnings 'uninitialized';

my $url_regex;
my %url_charmap;
my %entity_cache;

sub encode_html {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s/&/&amp;/gs;
    $str =~ s/"/&quot;/gs;
    $str =~ s/</&lt;/gs;
    $str =~ s/>/&gt;/gs;
    return $str;
}

sub uri_escape {
    my $str = shift;
    return '' unless defined $str;

    if ( not defined $url_regex ) {
        $url_regex = qr/[^A-Za-z0-9_\.~-]/;
    }

    if ( not scalar keys %url_charmap ) {
        %url_charmap = map { chr($_) => sprintf( '%%%02X', $_ ); }
            grep { chr($_) =~ m/^$url_regex$/ } 0 .. 255;
    }

    $str =~ s/($url_regex)/$url_charmap{$1}/gs;
    $str =~ s/\%20/+/gs;
    return $str;
}

sub encode_entities {
    my $str = shift;
    return '' unless defined $str;

    if ( not scalar keys %entity_cache ) {
        %entity_cache = (
            '&' => '&amp;',
            '"' => '&quot;',
            '<' => '&lt;',
            '>' => '&gt;',
        );
    }

    $str =~ s/([^\ \!\#\$\%\x28-\x3B\=\x3F-\x7E])/
		my $out = $entity_cache{$1};
		unless (defined $out)
		{
			$out = sprintf '&#x%X;', ord($1);
			$entity_cache{$1} = $out;
		}
		$out;
    /egsx;
    return $str;
}

1;
