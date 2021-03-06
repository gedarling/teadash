#!/usr/bin/perl
use Web::Simple 'TeaDash::Web';
{
  package TeaDash::Web;
  use Net::HTTP::Spore;
  use JSON::XS qw/encode_json decode_json/;
  use HTML::Zoom;
  use DateTime::Format::SQLite;
  use DateTime::Format::Strptime;
  use Try::Tiny;
  use Plack::App::File;
  use autodie;
  use feature ':5.10';
  
  local $/ = undef;
  open (my $fh, '<', 'config.json');
  my $config_file = <$fh>;
  my $config = decode_json($config_file);

  my $teatime = Net::HTTP::Spore->new_from_spec(
    $config->{dash}{spec_file},
    base_url => $config->{dash}{api_base_url}
  );
  
  $teatime->enable('Format::JSON');
  
  sub closed {
    my $self = shift;
    return [200, [ 'Content-Type', 'text/html'], ['TEA SERVER DOWN']];
  }
  
  sub today {
    my $self = shift;
    my $current_tea = $teatime->current->body;
    return "Today's tea is $current_tea->{data}{name}";  
  }
  
  sub last_status {
    my $self = shift;
    my $current_tea = $teatime->current->body;
  
    my $dt = DateTime::Format::SQLite->parse_datetime($current_tea->{data}{events}[0]{when})
      ->set_time_zone('UTC')
      ->set_time_zone('America/Chicago');
  
    my $strp = new DateTime::Format::Strptime(
      pattern     => '%I:%M %p',
      locale      => 'en_US',
      time_zone   => 'America/Chicago',
    );

    my $last_time = $strp->format_datetime( $dt );

    return "Last status: $current_tea->{data}{events}[0]{name} @ $last_time";
  } 
  
  sub details {
    my $self = shift;
    return $teatime->stats->body->{data};
  }
  
  sub events {
    my $self = shift;
    return $teatime->current->body->{data}{events};
  }
  
  sub pie {
    my $self = shift;
    my $stats = $teatime->stats->body;
    
    my @return = map {
      [ $_->{name}, $_->{count} ]
    } @{ $stats->{data}};
    
    return [200,[ 'Content-Type', 'text/json' ],[ encode_json(\@return) ]];
  }
  
  sub recent_history {
    my $self = shift;
    my @history = splice @{ $teatime->last_teas->body->{data} },0,10;
    return \@history;
  }
  
  sub main {
    my $self = shift;
    
    my $zoom = HTML::Zoom->from_file("$config->{dash}{webroot}/html/dash.html");

    $zoom = $zoom->select('title,#today')
      ->replace_content($self->today);
    
    $zoom = $zoom->select('#last_status')
      ->replace_content($self->last_status);
      
    $zoom = $zoom->select('#links')
      ->repeat_content([
        map {
          my $content = \"<a href='$_->[1]'>$_->[0]</a>";
          sub { $_->select('.link')->replace_content($content) }
        } @{ $config->{dash}{links} }
      ]);

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
    
    return [200,[ 'Content-Type', 'text/html'], [$zoom->to_html]];
  }
  
  my $files = Plack::App::File->new(root => $config->{dash}{webroot});
  
  sub dispatch_request {
    my $self = shift;
    (
    sub (/static/...) { $files },
    sub (/closed){
      my $self = shift;  
      $self->closed
    },
    sub (GET) {
      my $self = shift;
    
      return ( sub (GET) { $self->closed } ) unless try { $teatime->current->body }; 
      (
        sub (/) { $self->main },
        sub (/pie) { $self->pie },
      )
    }
    )
  };  
};

TeaDash::Web->run_if_script;