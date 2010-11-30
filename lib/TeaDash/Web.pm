#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
{
  package TeaDash::Web;
  use Net::HTTP::Spore;
  use JSON::XS qw/encode_json decode_json/;
  use HTML::Zoom;
  use Try::Tiny;
  use autodie;
  use feature ':5.10';
  
  local $/ = undef;
  open (my $fh, '<', 'lib/TeaDash/config.json');
  my $config_file = <$fh>;
  my $config = decode_json($config_file);

  my $teatime = Net::HTTP::Spore->new_from_spec(
    $config->{spec_file},
    api_base_url => $config->{api_base_url}
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
  
  sub closed {
    return _derp([ 'Content-type', 'text/html'], ['TEA SERVER DOWN']);
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
    return $teatime->stats->body->{data};
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
  
  sub recent_history {
    my @history = splice @{ $teatime->last_teas->body->{data} },0,10;
    return \@history;
  }
  
  sub main {
    my $zoom = HTML::Zoom->from_file('static/html/dash.html');
    
    $zoom = $zoom->select('title,#today')
      ->replace_content($self->today);
    
    $zoom = $zoom->select('#last_status')
      ->replace_content($self->last_status);
    
    $zoom = $zoom->select('#recent_history')
      ->repeat_content([
        map {
          my $recent_history = $_;
          my ($date,$time) = split(/ /,$recent_history->{events}[0]{when});
          sub {
            $_->select('.tea')->replace_content($recent_history->{name})
              ->select('.time')->replace_content($date);
          }
        } @{ $self->recent_history }
      ]);
    
    return _derp([ 'Content-type', 'text/html'], [$zoom->to_html] );
  }
  
  dispatch {
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
    sub (/closed){ $self->closed },
    subdispatch sub () {
      return [ sub () { $self->closed } ] unless try { $teatime->current->body }; 
      [
        sub (GET + /) { $self->main },
        sub (GET + /pie) { $self->pie },
      ]
    };
  };  
};

TeaDash::Web->run_if_script;