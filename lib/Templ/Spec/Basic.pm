package Templ::Spec::Basic;
use base 'Templ::Spec';

use strict;
use warnings;

use Templ (); # Loads all modules, but doesn't import anything

add Templ::Tag::Perl    '?';
add Templ::Tag::Print   '!';
add Templ::Tag::Comment '#';

1;
