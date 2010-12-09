package Geo::Coder::TomTom;

use strict;
use warnings;

use Carp qw(croak);
use JSON;
use LWP::UserAgent;
use URI;
use URI::Escape qw(uri_escape_utf8);

our $VERSION = '0.02';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (apikey => @params) : @params;

    my $self = bless \ %params, $class;

    $self->{apikey} ||= '1e2099c7-eea9-476b-aac9-b20dc7100af1';

    if ($params{ua}) {
        $self->ua($params{ua});
    }
    else {
        $self->{ua} = LWP::UserAgent->new(agent => "$class/$VERSION");
    }

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }

    $self->{compress} = 1 unless exists $self->{compress};
    $self->ua->default_header(accept_encoding => 'gzip,deflate')
        if $self->{compress};

    return $self;
}

sub response { $_[0]->{response} }

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $location = $params{location} or return;

    my $uri = URI->new('http://routes.tomtom.com');
    $uri->path(
        '/lbs/services/geocode/1/query/' . uri_escape_utf8($location) .
        '/json/' . $self->{apikey} . ';language=en;map=basic'
    );

    my $res = $self->{response} = $self->ua->get(
        $uri, referer => 'http://routes.tomtom.com/'
    );
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    # Result is a list only if there is more than one item.
    my $results = $data->{geoResponse}{geoResult};
    my @results = 'ARRAY' eq ref $results ? @$results : ($results);

    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::TomTom - Geocode addresses with the TomTom route planner

=head1 SYNOPSIS

    use Geo::Coder::TomTom;

    my $geocoder = Geo::Coder::TomTom->new;
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::TomTom> module provides an interface to the geocoding
service of the TomTom route planner through the unofficial (as-yet
unpublished) REST API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::TomTom->new();

Creates a new geocoding object.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        category         => 7373,
        city             => "Hollywood",
        country          => "United States",
        countryISO3      => "USA",
        formattedAddress => "Hollywood & Highland, Hollywood, CA, US",
        geohash          => "9q5cgpgrfetr",
        heightMeters     => 0,
        latitude         => "34.10154",
        longitude        => "-118.34015",
        mapName          => "usacanadaandmexicop",
        name             => "Hollywood & Highland",
        score            => 1,
        state            => "CA",
        type             => "poi",
        widthMeters      => 0,
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://routes.tomtom.com/>

L<Geo::Coder::Bing>, L<Geo::Coder::Bing::Bulk>, L<Geo::Coder::Google>,
L<Geo::Coder::Mapquest>, L<Geo::Coder::Multimap>, L<Geo::Coder::Navteq>,
L<Geo::Coder::OSM>, L<Geo::Coder::PlaceFinder>, L<Geo::Coder::SimpleGeo>,
L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-TomTom>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::TomTom

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-tomtom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-TomTom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-TomTom>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-TomTom>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-TomTom/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
