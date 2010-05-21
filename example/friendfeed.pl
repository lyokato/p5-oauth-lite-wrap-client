#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Perl6::Say;
use lib "$FindBin::Bin/../lib";

use OAuth::Lite::WRAP::Client::WebApp;
use OAuth::Lite::WRAP::Client::Agent::Dump;

my $client_id     = q{};
my $client_secret = q{};
my $callback_url  = q{};

my $client = OAuth::Lite::WRAP::Client::WebApp->new(
    id               => $client_id,
    secret           => $client_secret,
    authorize_url    => q{https://friendfeed.com/account/wrap/authorize},
    access_token_url => q{https://friendfeed.com/account/wrap/access_token},
    agent            => OAuth::Lite::WRAP::Client::Agent::Dump->new,
);


my $url = $client->url_to_redirect(
    callback_url => $callback_url,
);

say "[ACCESS TO THIS PAGE AND PUSH ALLOW BUTTON]";
say $url;
say "";

say "[INPUT THE VERIFICATION CODE YOU GOT]";
my $code;
print "> ";
while ($code = <STDIN>) {
    chomp $code;
    last;
}

my $res = $client->get_access_token(
    verification_code => $code,
    callback_url      => $callback_url,
);

unless ($res) {
    say "[FAILED TO GET ACCESS TOKEN]";
    die $client->errstr;
}

say "[GOT ACCESS TOKEN]";
say $res->access_token;
say "[GOT REFRESH TOKEN]";
say $res->refresh_token;

if ($res->expires_in) {
    say "[expires_in FOUND]";
    say $res->expires_in;
} else {
    say "[expires_in NOT FOUND]";
}


=pod

# no refresh token endpoint yet.

say "[REFRESH TOKEN]";
my $res2 = $client->refresh_access_token(
    refresh_token => $res->refresh_token,
);

unless ($res2) {
    say "[FAILED TO REFRESH TOKEN]";
    die $client->errstr;
}

say "[GOT REFRESHED ACCESS TOKEN]";
say $res2->access_token;

=cut
