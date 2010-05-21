package OAuth::Lite::WRAP::Client::WebApp::RequestBuilder;

use strict;
use warnings;

use Params::Validate qw(HASHREF);
use OAuth::Lite::Util qw(encode_param);
use HTTP::Request;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub build_access_token_request {
    my $self = shift;

    my %args = Params::Validate::validate(@_, {
        client_id         => 1,
        client_secret     => 1,
        verification_code => 1,
        callback_url      => 1,
        url               => 1,
        extra => { optional => 1, type => HASHREF },
    });

    my %params = (
        wrap_client_id         => $args{client_id},
        wrap_client_secret     => $args{client_secret},
        wrap_verification_code => $args{verification_code},
        wrap_callback          => $args{callback_url},
    );

    if ($args{extra}) {
        for my $key ( keys %{$args{extra}} ) {
            $params{$key} = $args{extra}{$key};
        }
    }

    return $self->_build_request($args{url}, \%params);
}

sub build_refresh_token_request {
    my $self = shift;

    my %args = Params::Validate::validate(@_, {
        client_id     => 1,
        client_secret => 1,
        refresh_token => 1,
        url           => 1,
        extra => { optional => 1, type => HASHREF },
    });

    my %params = (
        wrap_client_id     => $args{client_id},
        wrap_client_secret => $args{client_secret},
        wrap_refresh_token => $args{refresh_token},
    );

    if ($args{extra}) {
        for my $key ( keys %{$args{extra}} ) {
            $params{$key} = $args{extra}{$key};
        }
    }
    return $self->_build_request($args{url}, \%params);
}

sub _build_request {
    my ($self, $url, $params) = @_;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type(q{application/x-www-form-urlencoded});
    $req->content($self->_build_content($params));
    return $req;
}

sub _build_content {
    my ($self, $params) = @_;
    return join("&", sort map {sprintf(q{%s=%s},
        encode_param($_),
        encode_param($params->{$_}),
    ) } keys %$params);
}


1;
