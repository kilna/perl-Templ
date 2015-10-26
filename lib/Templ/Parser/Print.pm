
package Templ::Parser::Print;
use base 'Templ::Parser';

use strict;
use warnings;

sub pretty_header { return "use feature 'say';\n"; }
sub header        { return 'print ';               }
sub append        { return 'print ';               }
sub append_pretty { return 'say ';                 }
sub footer        { return ";\n";                  }

1;
