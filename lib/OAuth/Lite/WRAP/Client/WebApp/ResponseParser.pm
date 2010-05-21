package OAuth::Lite::WRAP::Client::WebApp::ResponseParser;

use strict;
use warnings;

use OAuth::Lite::WRAP::Client::Response;
use OAuth::Lite::WRAP::Client::Error;
use Try::Tiny;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub parse_access_token_response {
    my ($self, $http_res) = @_;

    if ($http_res->is_success) {

        my $res = $self->_parse_response($http_res);

        OAuth::Lite::WRAP::Client::Error::TokenRequestFailed->throw(
            $res->error_reason) if $res->error_reason;

        OAuth::Lite::WRAP::Client::Error::MissingParam->throw(
            "wrap_access_token not found")
            unless defined $res->access_token;

        OAuth::Lite::WRAP::Client::Error::MissingParam->throw(
            "wrap_refresh_token not found")
            unless defined $res->refresh_token;

        return $res;

    } else {

        my $error = $http_res->status_line;
        if ($http_res->content) {
            try {
                my $res = $self->_parse_response($http_res);
                $error = $res->error_reason if $res->error_reason;
            } catch {
                $error = $_;
            };
        }

        OAuth::Lite::WRAP::Client::Error::TokenRequestFailed->throw($error);
    }
}

sub parse_refresh_token_response {
    my ($self, $http_res) = @_;

    if ($http_res->is_success) {

        my $res = $self->_parse_response($http_res);

        OAuth::Lite::WRAP::Client::Error::TokenRequestFailed->throw(
            $res->error_reason) if $res->error_reason;

        OAuth::Lite::WRAP::Client::Error::MissingParam->throw(
            "wrap_access_token not found")
            unless defined $res->access_token;

        return $res;

    } else {

        my $error = $http_res->status_line;

        if ($http_res->content) {
            try {
                my $res = $self->_parse_response($http_res);
                $error = $res->error_reason if $res->error_reason;
            } catch {
                $error = $_;
            };
        }

        OAuth::Lite::WRAP::Client::Error::TokenRequestFailed->throw($error);
    }
}

sub _parse_response {
    my ($self, $res) = @_;

    OAuth::Lite::WRAP::Client::Error::MissingParam->throw(
        "all params not found.") unless $res->content;

    return OAuth::Lite::WRAP::Client::Response->parse($res->content);
}

1;
