package OAuth::Lite::WRAP::Client::Response;

use strict;
use warnings;

use overload q{""} => \&as_string, fallback => 1;

use OAuth::Lite::Util qw(encode_param decode_param);

=head1 NAME

OAuth::Lite::WRAP::Client::Response - Token response

=head1 SYNOPSIS

    my $res = OAuth::Lite::WRAP::Client::Response->parse( $http_res->content );
    say $res->access_token;
    say $res->refresh_token;
    say $res->expires_in;
    say $res->error_reason;
    say $res->param('other_param');

=head1 DESCRIPTION

=head1 METHODS

=head2 parse ($content)

    my $res = OAuth::Lite::WRAP::Client::Response->parse( $http_res->content );

Parse form-urlencoded formatted string ( body of response from access_token endpoint ),
And returns this class's object.

=cut

sub parse {
    my ($class, $content) = @_;
    my %params;
    for my $pair ( split /\&/, $content ) {
        my ($key, $value) = split /\=/, $pair;
        next unless defined $key && $key ne '';
        $value ||= '';
        $params{decode_param($key)} = decode_param($value);
    }
    return $class->new(%params);
}

=head2 new (%args)

=cut

sub new {
    my $class = shift;
    bless {
        wrap_access_token            => undef,
        wrap_refresh_token           => undef,
        @_
    }, $class;
}

=head2 access_token

Accessor for wrap_access_token.

=head2 refresh_token

Accessor for wrap_refresh_token.

=head2 error_reason

Accessor for wrap_error_reason.

=head2 expires_in

Accessor for wrap_access_token_expires_in.

=head2 param ($key)

    my $value = $res->param('wrap_error_reason');

=cut

sub access_token  { $_[0]->{wrap_access_token}            }
sub refresh_token { $_[0]->{wrap_refresh_token}           }
sub expires_in    { $_[0]->{wrap_access_token_expires_in} }
sub error_reason  { $_[0]->{wrap_error_reason}            }
sub param         { $_[0]->{ $_[1] }                      }

=head2 as_string

Returns params as string with form-urlencoded format.

=cut

sub as_string {
    my $self = shift;
    my %params = %$self;
    return join("&", sort map {sprintf(q{%s=%s},
        encode_param($_),
        encode_param($params{$_}||''),
    ) } keys %params);
}

1;

=head1 AUTHOR

Lyo Kato, C<lyo.kato _at_ gmail.com>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
