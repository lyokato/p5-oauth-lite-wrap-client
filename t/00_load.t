use Test::More tests => 9;

BEGIN {
  use_ok("OAuth::Lite::WRAP::Client");
  use_ok("OAuth::Lite::WRAP::Client::WebApp");
  use_ok("OAuth::Lite::WRAP::Client::WebApp::RequestBuilder");
  use_ok("OAuth::Lite::WRAP::Client::WebApp::ResponseParser");
  use_ok("OAuth::Lite::WRAP::Client::Error");
  use_ok("OAuth::Lite::WRAP::Client::Response");
  use_ok("OAuth::Lite::WRAP::Client::Agent");
  use_ok("OAuth::Lite::WRAP::Client::Agent::Dump");
  use_ok("OAuth::Lite::WRAP::Client::Agent::Strict");
}

