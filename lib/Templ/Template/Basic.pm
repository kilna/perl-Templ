package Templ::Template::Basic;
use base 'Templ::Template';

use strict;
use warnings;

use Templ::Template; # Import the add_* subs

add_tag '*' => 'Perl';
add_tag '@' => 'Print';
add_tag '#' => 'Comment';

1;
