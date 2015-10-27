use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Templ',
    license             => 'perl',
    dist_author         => q{Anthony Kilna <kilna@kilna.com>},
    dist_version_from   => 'lib/Templ.pm',
    dist_abstract       => 'A lightweight, pure perl system for building templating systems',
    configure_requires => { 
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'    => 0,
        'FindBin'       => 0,
    },
    requires => {
        'perl'                  => 5.008,
        'Carp'                  => 0,
        'Digest::MD5'           => 0,
        'Exporter'              => 0,
        'File::Spec::Functions' => 0,
        'HTML::Entities'        => 0,
        'Scalar::Util'          => 0,
        'Symbol'                => 0,
        'URI::Escape'           => 0,
    },
    add_to_cleanup      => [ 'Templ-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
