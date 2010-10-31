#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
{
  package TeaDash::Web;
  use Net::HTTP::Spore;
  use JSON::XS qw/encode_json/;
  use HTML::Zoom;
  use autodie;
  use feature ':5.10';
  
  my $teatime = Net::HTTP::Spore->new_from_spec(
    '/home/geoff/code/teadash/lib/TeaDash/teatime.json',
    api_base_url => 'http://localhost:5000'
  );
  
  $teatime->enable('Format::JSON');
  
  sub _derp {
    my $headers = shift;
    my $data = shift;
    
    [
      200,
      $headers,
      $data  
    ]
  }
  
  sub today {
    my $current_tea = $teatime->current->body;
    
    return "Today's tea is $current_tea->{data}{name}";  
  }
  
  sub last_status {
    my $current_tea = $teatime->current->body;
    
    return "Last status: $current_tea->{data}{events}[0]{name} @ $current_tea->{data}{events}[0]{when}";
  }
  
  sub details {
    my $stats = $teatime->stats->body;
    
    return $stats->{data};
  }
  
  sub events {
    return $teatime->current->body->{data}{events};
  }
  
  sub pie {
    my $stats = $teatime->stats->body;
    
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
    
    $zoom = $zoom->select('#last_status')
      ->replace_content($self->last_status);
    
    $zoom = $zoom->select('#events')
      ->repeat_content([
        map {
          my $events = $_;
          sub {
            $_->select('.event')->replace_content($events->{name})
              ->select('.time')->replace_content($events->{when});
          }
        } @{ $self->events }
      ]);
    
    return _derp([ 'Content-type', 'text/html'], [$zoom->to_html] );
  }
  
  dispatch {
    sub (GET + /) { $self->main },
    sub (GET + /test) { $self->pie },
    sub (/static/**) {
      my $file = $_[1];
      
      my $content_type;
      given ($file) {
        when (/.js/){
          $content_type = 'text/javascript';
        }
        when (/.css/){
          $content_type = 'text/css';
        }
        default {
          $content_type = 'text/html';
        }
      };
      
      open my $fh, '<', "static/$file" or return [ 404, [ 'Content-type', $content_type ], [ 'file not found']];
      local $/ = undef;
      my $data = <$fh>;
      close $fh or return [ 500, [ 'Content-type', $content_type ], [ 'Internal Server Error'] ];
      [ 200, [ 'Content-type' => $content_type ], [ $data ] ]
    },    
  };  
};

TeaDash::Web->run_if_script;