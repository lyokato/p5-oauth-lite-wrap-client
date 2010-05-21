package OAuth::Lite::WRAP::Client::WebApp;

use strict;
use warnings;

use base 'Class::ErrorHandler';

use Carp;
use URI;
use Try::Tiny;
use LWP::UserAgent;
use Params::Validate qw(HASHREF);

use OAuth::Lite::WRAP::Client::WebApp::RequestBuilder;
use OAuth::Lite::WRAP::Client::WebApp::ResponseParser;
use OAuth::Lite::WRAP::Client::Error;

=head1 NAME

OAuth::Lite::WRAP::Client::WebApp - Client Library for OAuth WRAP WebApp Profile

=head1 SYNOPSIS

    my $client = OAuth::Lite::WRAP::Client::WebApp->new(
        id                => $client_id,
        secret            => $client_secret,
        authorize_url     => q{http://example.org/wrap/authorize},
        access_token_url  => q{http://example.org/wrap/token},
        refresh_token_url => q{http://example.org/wrap/token},
    );

    sub do_something_with_protected_resource {
        my $your_app = shift;

        my $token = $your_app->get_token_for( $your_app->current_user );

        if ($token) {

            if ($token->expires_in > time()) {

                my $req = HTTP::Request->new( GET => q{https://provider.example.org/protected_resource} );
                $req->header( Authorization => sprintf q{WRAP access_token="%s"}, $token->access_token );
                ...

                my $res = $your_app->agent->request( $req );

                if ($res->is_success) {

                    $your_app->do_some_stuff($res->content);

                } else {


                }


            } else {

                # access token is expired, so refresh token

                my $res = $your_app->refresh_access_token(
                    refresh_token => $token->refresh_token,
                );

                if ($res) {

                    $your_app->save_access_token( $your_app->current_user => {
                        access_token  => $res->access_token,
                        resresh_token => $res->resresh_token,
                        expires_in    => $res->expires_in,
                    } );

                    # retry
                    $your_app->do_something_with_protected_resource();

                } else {

                    $your_app->res->error( $client->errstr );

                }



            }

        } else {

            $your_app->start_authorize();

        }
    }

    sub start_authorize {
        my $your_app = shift;

        my $url = $client->url_to_redirect(
            callback_url => q{http://example.org/callback_handler},
            state        => q{foobar},
            scope        => q{email},
        );

        $your_app->res->redirect($url);
    }


    # this methods corresponds to the url endpoint
    # 'http://example.org/callback_handler'

    sub callback_handler {

        my $your_app = shift;

        if (my $code = $your_app->req->param('wrap_verification_code')) {

            my $state = $your_app->req->param('wrap_client_state');
            # $state should be "foobar" in this case.

            my $res = $client->get_access_token(
                verification_code => $code,
                callback_url      => q{http://example.org/callback_handler},
            );

            if ($res) {

                $your_app->save_access_token( $your_app->current_user => {
                    access_token  => $res->access_token,
                    resresh_token => $res->resresh_token,
                    expires_in    => $res->expires_in,
                } );

            } else {

                $your_app->res->error( $client->errstr );

            }

        } elsif (my $error_reason = $your_app->req->param('wrap_error_reason')) {

            my $state = $your_app->req->param('wrap_client_state');
            # $state should be "foobar" in this case.

            $your_app->res->error( $error_reason );
            return;

        } else {

            $your_app->res->error( 'request is not an oauth authorization callback' );
            return;

        }
    }

=head1 DESCRIPTION

This module is client library for OAuth WRAP WebApp Profile.
This is implemented according to the spec(v0.9.7.2), L<http://wiki.oauth.net/OAuth-WRAP>.

=head1 METHODS

=head2 new (%args)

Following arguments can be passed as %args.

=over

=item id

Required.
This clinet id (called "consumer key" on OAuth1.0 spec)

=item secret

Required.
This clinet id (called "consumer secret" on OAuth1.0 spec)

=item authorize_url

The web page url that is for a user to authorize that your service accesses to
the user's protected resources.

=item access_token_url

And endpoint url that a provider verify and issue new access token.

=item refresh_token_url

Optinal.
An endpoint url that a provider allows you to refresh your access token.
In many cases, refresh_token_url is same as access_token_url. So,
When you omit this, access_token_url is used as refresh token endpoint.

=item agent

Optional.
If you omit this, the simple LWP::UserAgent object is set by default.
You can use your custom agent which has same 'request' method interface as LWP::UserAgent.

See also agent-presets, L<OAuth::Lite::WRAP::Clinet::Agent::Dump>,
L<OAuth::Lite::WRAP::Clinet::Agent::Strict>.

=back

=cut

sub new {

    my $class = shift;

    my %args = Params::Validate::validate(@_, {
        id                => 1,
        secret            => 1,
        authorize_url     => { optional => 1 },
        access_token_url  => { optional => 1 },
        refresh_token_url => { optional => 1 },
        agent             => { optional => 1 },
    });

    my $self = bless {
        id                => undef,
        secret            => undef,
        authorize_url     => undef,
        access_token_url  => undef,
        refresh_token_url => undef,
        %args,
    }, $class;

    unless ($self->{agent}) {
        $self->{agent} = LWP::UserAgent->new;
        $self->{agent}->agent(
            join "/", __PACKAGE__, $OAuth::Lite::WRAP::Clinet::VERSION);
    }

    $self->{request_builder} =
        OAuth::Lite::WRAP::Client::WebApp::RequestBuilder->new;

    $self->{response_parser} =
        OAuth::Lite::WRAP::Client::WebApp::ResponseParser->new;

    return $self;
}

=head2 url_to_redirect (%args)

    my $url = $client->url_to_redirect(
        callback_url => q{http://example.org/callback},
    );
    $your_app->response->redirect($url);

Following arguments can be passed as %args.

=over

=item callback_url

The url that user returns to after authroization.

=item state

Optional.

If you want to keep user's state, use this param.
You pass this param then after user authorized on server and
returns to callback_url with this param as it is.

=item scope

Optional.

Set according to servers description about their namespace that represents
kinds of protected resource.

=item url

Optional.

Server's authorization endpoint.
You don't need to set this parameter if you set authorize_url at constructor.

=item extra

Optional.

Extra parameters server requires.
Set this as hash reference.

=back

=cut

sub url_to_redirect {
    my $self = shift;

    my %args = Params::Validate::validate(@_, {
        callback_url => 1,
        state => { optional => 1 },
        scope => { optional => 1 },
        url   => { optional => 1 },
        extra => { optional => 1, type => HASHREF },
    });

    my %params = (
        wrap_client_id => $self->{id},
        wrap_callback  => $args{callback_url},
    );

    $params{wrap_client_state} = $args{state} if $args{state};
    $params{wrap_scope}        = $args{scope} if $args{scope};

    if ($args{extra}) {
        for my $key ( keys %{$args{extra}} ) {
            next if $key =~ /^wrap_/;
            $params{$key} = $args{extra}{$key};
        }
    }

    my $url = $args{url}
        || $self->{authorize_url}
        || Carp::croak "url not found";

    my $uri = URI->new($url);
    $uri->query_form(%params);
    return $uri->as_string;
}

=head2 get_access_token (%args)

    my $res = $client->get_access_token(
        verification_code => $code,
        callback_url      => q{http://example.org/callback},
    ) or $your_app->error( $client->errstr );

    say $res->access_token;
    say $res->refresh_token;
    say $res->expires_in;

Following arguments can be passed as %args.

=over

=item verification_code

Required.

The code that your app gets when user returns to callback_url endpoint you indicated when
your app redirects the user.

=item callback_url

Required.

The callback_url endpoint you indicated when your app redirects the user.

=item url

Optional.

Server's access token endpoint.
You don't need to set this parameter if you set access_token_url at constructor.

=item extra

Optional.

Extra parameters server requires.
Set this as hash reference.

=back

The response is L<OAuth::Lite::WRAP::Client::Response> object.

=cut

sub get_access_token {
    my ($self, %args) = @_;

    unless (exists $args{url}) {
        $args{url} = $self->{access_token_url}
            || Carp::croak "url not found";
    }

    my $http_req = $self->{request_builder}->build_access_token_request(
        client_id     => $self->{id},
        client_secret => $self->{secret},
        %args,
    );

    my $error;
    my $token = try {
        my $http_res = $self->{agent}->request($http_req);
        return $self->{response_parser}->parse_access_token_response($http_res);
    } catch {
        $error = $_;
        return;
    };

    return $token || $self->error($error);
}

=head2 refresh_access_token (%args)

    my $res = $client->refresh_access_token(
        refresh_token => $refresh_token,
    ) or $your_app->error( $client->errstr );

    say $res->access_token;
    say $res->expires_in;

Following arguments can be passed as %args.

=over

=item refresh_token

Required.

The refresh token value included in the response that you got as a result of
'get_access_token' method.

=item url

Optional.

Server's refresh token endpoint.
You don't need to set this parameter if you set refresh_token_url or access_token_url at constructor.
If you set this parameter, it is priored to other parameters.
If you don't set this, this method uses refresh_token_url parameter you set at constructor.
If you don't set both this and refresh_token_url, this methods uses access_token_url
parameter you set at constructor.

=item extra

Optional.

Extra parameters server requires.
Set this as hash reference.

=back

The response is L<OAuth::Lite::WRAP::Client::Response> object.

=cut

sub refresh_access_token {
    my ($self, %args) = @_;

    unless (exists $args{url}) {
        $args{url} = $self->{refresh_token_url}
            || $self->{access_token_url}
            || Carp::croak "url not found";
    }

    my $http_req = $self->{request_builder}->build_refresh_token_request(
        client_id     => $self->{id},
        client_secret => $self->{secret},
        %args
    );

    my $error;
    my $token = try {
        my $http_res = $self->{agent}->request($http_req);
        return $self->{response_parser}->parse_refresh_token_response($http_res);
    } catch {
        $error = $_;
        return;
    };

    return $token || $self->error($error);
}

1;

=head1 AUTHOR

Lyo Kato, C<lyo.kato _at_ gmail.com>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
