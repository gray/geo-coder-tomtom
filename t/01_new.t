use strict;
use warnings;
use Test::More tests => 3;
use Geo::Coder::TomTom;

new_ok('Geo::Coder::TomTom' => []);
new_ok('Geo::Coder::TomTom' => [debug => 1]);

can_ok('Geo::Coder::TomTom', qw(geocode response ua));
