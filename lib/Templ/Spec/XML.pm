package Templ::Spec::XML;
use base 'Templ::Spec::Basic';

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(encode_xml encode_entities cdata);

use strict;
use warnings;
use Templ (); # Loads all modules, but doesn't import anything
use Carp qw(croak);

add Templ::Header 'use Templ::Spec::XML;';
add Templ::Tag::Filter '&' => 'encode_xml';
add Templ::Tag::Filter ';' => 'encode_entities';
add Templ::Tag::Filter '|' => 'cdata';

my %entity_cache = (
    '&' => '&amp;',
    '"' => '&quot;',
    "'" => '&apos;',
    '<' => '&lt;',
    '>' => '&gt;',
);

sub encode_xml {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s/&/&amp;/gs;
    $str =~ s/"/&quot;/gs;
    $str =~ s/'/&apos;/gs;
    $str =~ s/</&lt;/gs;
    $str =~ s/>/&gt;/gs;
    return $str;
}

sub encode_entities {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s<([^\ \!\#\$\%\x28-\x3B\=\x3F-\x7E])>
    <
        my $out = $entity_cache{$1};
        unless (defined $out) {
            $out = sprintf '&#x%X;', ord($1);
            $entity_cache{$1} = $out;
        }
        $out;
    >egsx;
    return $str;
}

sub cdata {
    my $str = shift;
    croak "Cannot perform cdata insert: data contains string ']]>'"
        if $str =~ m/\]\]>/;
    return "<![CDATA[$str]]>";

}

1;
