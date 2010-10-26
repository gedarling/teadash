#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
{
  package TeaDash::Web;
  use JSON::XS qw/encode_json decode_json/;
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
    
    return "Today's tea is $current_tea->{data}{name}";  
  }
  
  sub details {
    my $stats = decode_json(
      LWP::Simple::get('http://localhost:5000/stats')
    );
    
    return $stats->{data};
  }
  
  sub pie {
    my $stats = decode_json(
      LWP::Simple::get('http://192.168.1.5:5000/stats')
    );
    
    my @return = map {
      [ $_->{name}, $_->{count} ]
    } @{ $stats->{data}};
    
    return _derp([ 'Content-type', 'text/json' ],
      [ encode_json(\@return) ]
    );
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
    
    return _derp([ 'Content-type', 'text/html'], [$zoom->to_html] );
  }
  
  dispatch {
    sub (GET + /) { $self->main },
    sub (GET + /test) { $self->pie },
    sub (/static/**) {
      my $file = $_[1];
      open my $fh, '<', "static/$file" or return [ 404, [ 'Content-type', 'text/html' ], [ 'file not found']];
      local $/ = undef;
      my $data = <$fh>;
      close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];
      [ 200, [ 'Content-type' => 'text/html' ], [ $data ] ]
    },    
  };  
};

TeaDash::Web->run_if_script;