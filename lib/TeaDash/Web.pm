#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
{
  package TeaDash::Web;
  use JSON::XS qw/decode_json/;
  use LWP::Simple;
  use HTML::Zoom;
  use autodie;
  
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
    my $current_tea = decode_json(
      LWP::Simple::get('http://localhost:5000/current_tea')
    );
    
    return "Today's tea is $current_tea->{data}[0]{name}";  
  }
  
  sub details {
    my $stats = decode_json(
      LWP::Simple::get('http://localhost:5000/stats')
    );
    
    return $stats->{data};
  }
  
  sub main {
    my $zoom = HTML::Zoom->from_file('static/html/dash.html');
    
    $zoom = $zoom->select('title,#today')
      ->replace_content($self->today);
    
    $zoom = $zoom->select('#stats')
      ->repeat_content([
        map {
          my $details = $_;
          sub {
            $_->select('.name')->replace_content($details->{name})
              ->select('.count')->replace_content($details->{count});
          }
        } @{ $self->details }
      ]);
    
    return _derp([ 'Content-type', 'text/html' ], [$zoom->to_html] );
  }
  
  dispatch {
    sub (GET) { $self->main },
  };  
};

TeaDash::Web->run_if_script;