use strict;
use warnings;

use Test::More tests => 10;

use OAuth::Lite::WRAP::Client::Error;
use Try::Tiny;

sub check {
    my $class = shift;
    my $type_check = 0;
    my $message = "";
    try {
        $class->throw("foo");
    } catch {
        $type_check = 1 if $_->isa($class);
        $message = $_->message;
    };

    ok($type_check, "type check for $class");
    is($message, "foo", "message check");
};

&check($_) for qw(
    OAuth::Lite::WRAP::Client::Error::TokenRequestFailed
    OAuth::Lite::WRAP::Client::Error::MissingParam
    OAuth::Lite::WRAP::Client::Error::InsecureRequest
    OAuth::Lite::WRAP::Client::Error::InsecureResponse
    OAuth::Lite::WRAP::Client::Error::InvalidResponseFormat
);
