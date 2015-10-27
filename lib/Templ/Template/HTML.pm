package Templ::Template::HTML;
use base 'Templ::Template::Basic'; # Inherit T::T::Basic's tags, too!

use strict;
use warnings;

use Templ::Template; # Import the add_* subs

add_header 'use Templ::Filter::HTML;';
add_tag '&' => 'Filter', 'filter' => 'encode_html';
add_tag ';' => 'Filter', 'filter' => 'encode_entities';
add_tag '%' => 'Filter', 'filter' => 'uri_escape';

1;
