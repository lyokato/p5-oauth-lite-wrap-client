use strict;
use warnings;

use inc::Module::Install;

name 'OAuth-Lite-WRAP-Client';
all_from 'lib/OAuth/Lite/WRAP/Client.pm';

requires(
    'Net::SSLeay'         => 0,
    'OAuth::Lite'         => 0,
    'Parmas::Validate'    => 0,
    'LWP::UserAgent'      => 0,
    'Try::Tiny'           => 0,
    'Class::ErrorHandler' => 0,
);

tests('t/*.t t/*/*.t');

#author_tests('xt');
test_requires(
    'Test::More' => 0,
    #    'Test::Class' => 0,
);

auto_include;
WriteAll;
