#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
use LWP::Simple;
{
  package TeaDash::Web;
  use JSON::XS qw/decode_json/;
  
  sub _derp {
    my $headers = shift;
    my $data = shift;
    my $root = 'http://localhost:3000';
    
    [
      200,
      $headers,
      $data  
    ]
  }
  
  sub today {
    use Devel::Dwarn;
    use HTML::Tags;
    
    my $current_tea = decode_json(LWP::Simple::get('http://localhost:5000/current_tea'));
    
    my $ct_name = $current_tea->{data}[0]{name};
    
    return (
      <h1>,'Today\'s Tea!',</h1>,
      <p>,$ct_name,</p>,
    );   
  }
  
  sub wes_sucks {
    use HTML::Tags;
    
    return (
      <p>,'wes sucks cox n dix',</p>
    );
  }
  
  sub main {
    use HTML::Tags;
    my $body = join '', HTML::Tags::to_html_string(
      <html>,
      <body>,
        $self->today,
        $self->wes_sucks,
      </body>,
      </html>
    );
    
    return _derp([ 'Content-type', 'text/html' ], [$body] );
  }
  
  dispatch {
    sub (GET) { $self->main },
  };  
};

TeaDash::Web->run_if_script;