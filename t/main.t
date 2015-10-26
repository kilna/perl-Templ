#!perl

use strict;
use warnings;

use FindBin;
use Test::More 'tests' => 17;

BEGIN {
    use_ok('Templ'); # This should in turn load all Templ:: modules in @INC
}
is( templ_spec, 'Templ::Spec::Basic', 'spec defaulted correctly' );

my $t = templ Templ::Spec::HTML file => "$FindBin::Bin/main.templ";
isa_ok( $t, 'Templ::Spec::HTML' );

is( templ_spec, 'Templ::Spec::Basic', 'object instance did not mess with templ_spec' );

my $captured = '';
{
    binmode STDOUT, ':utf8';
    local *STDOUT;
    open STDOUT, '>', \$captured
         || BAIL_OUT("Unable to redirect STDOUT to variable");    
    $t->run();
}

like( $captured, qr/(  <num>0\d<\/num>\n){3,3}/, 'perl code executed on file' );

templ_spec 'HTML';
is( templ_spec, 'Templ::Spec::HTML', 'spec set correctly after templ_spec' );
$t = templ <<'EOF';
<? my %info = @_; ?>
<? while (my ($k,$v) = each(%info) ) { ?>
<#- Testing commenting -#>
  <kv key="<% uc($k) %>" entity="<; $v ;>" html="<& $v &>"/>
<? } ?>
EOF
isa_ok( $t, 'Templ::Spec::HTML' );

my $out = $t->render( 'smile?' => "\x{263A}" );
my $find = '<kv key="SMILE%3F" entity="&#x263A;" html="'."\x{263A}".'"/>'."\n";
is( $out, $find, 'uri / entities 1' );

$out = $t->( 'space bar!' => "&" );
$find = '<kv key="SPACE+BAR%21" entity="&amp;" html="&amp;"/>'."\n";
is( $out, $find, 'uri / entities 2' );

##############################################################################

package TestSpec;
use base 'Templ::Spec::Basic';
use Templ (); # Loads all modules, but doesn't import anything
add Templ::Tag::Comment '[';

##############################################################################

package TestObj;

use Templ '-spec' => 'XML';

sub new    { my $class = shift; return bless { @_ }, $class; }
sub name   { shift->{'name'}   }
sub rank   { shift->{'rank'}   }
sub serial { shift->{'serial'} }

my $m1 = 
templ_method as_xml => <<'EOF';
<xml>
    <name><& lc($self->name) &></name>
    <rank><& uc($self->rank) &></rank>
    <serial><& $self->serial &></serial>
</xml>
EOF
Test::More::isa_ok( $m1, 'Templ::Spec::XML' );
Test::More::can_ok( 'TestObj', 'as_xml' );

my $m2 =
templ_method TestSpec as_text => <<'EOF';
<[
    This is a comment.
    The plus signs preserve the newlines after the tag
]>
<! $self->name   +!>
<! $self->rank   +!>
<! $self->serial +!>
<# Another comment using a different tag spec... #>
EOF
Test::More::isa_ok( $m2, 'TestSpec' );
Test::More::can_ok( 'TestObj', 'as_text' );

##############################################################################

package main;

my $thing = TestObj->new(
    'name'   => 'ASDF',
    'rank'   => 'colonel.',
    'serial' => '1234',
);
                    
my $xml = $thing->as_xml;
my $expect_xml = <<'EOF';
<xml>
    <name>asdf</name>
    <rank>COLONEL.</rank>
    <serial>1234</serial>
</xml>
EOF
is( $xml, $expect_xml, 'xml returned by object is good' );

my $text = $thing->as_text;
my $expect_text = <<'EOF';
ASDF
colonel.
1234
EOF
is( $text, $expect_text, 'text returned by object is good' );

my $t2 = new Templ::Spec::Basic \*DATA;
isa_ok( $t2, 'Templ::Spec::Basic' );

my $out2 = $t2->render(0..6);
my $expect_out2 = <<'EOF';
  [0 - 00]
  [1 - 02]
  [2 - 04]
  [3 - 06]
  [4 - 08]
  [5 - 10]
  [6 - 12]
EOF

is( $out2, $expect_out2, 'filehandle output correct' );

__DATA__
<? foreach (@_) { ?>
  [<! $_ !> - <! sprintf('%0.2d', ($_ * 2) ) !>]
<? } ?>
