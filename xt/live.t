use strict;
use warnings;
use Encode;
use Geo::Coder::TomTom;
use Test::More;

my $debug = $ENV{GEO_CODER_TOMTOM_DEBUG};
diag "Set GEO_CODER_TOMTOM_DEBUG to see request/response data"
    unless $debug;

my $geocoder = Geo::Coder::TomTom->new(
    debug    => $debug,
    compress => 0,
);
{
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is(
        $location->{city},
        'Los Angeles',
        "correct city for $address"
    );
}
{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{country}, 'Germany', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{country}, 'Germany', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{country}, 'Germany', 'UTF-8 bytes');
    is($location->{houseNumber}, 6, 'UTF-8 bytes: parsed street address');
}
{
    my $city = decode('latin1', qq(Schm\xF6ckwitz));
    my $location = $geocoder->geocode("$city, Berlin, Germany");
    is(
        $location->{district}, $city,
        'decoded character encoding of response'
    );
}

done_testing;
