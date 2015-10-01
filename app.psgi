use Mojolicious::Lite;

use File::Spec;
use File::Temp qw/ tempfile tempdir /;
use Imager;

use lib 'lib';
use RemoteImageDriver::Imager;

our $VERSION = '0.01';

my $temp_dir = tempdir();

helper 'upload_file' => sub {
    my $c = shift;

    my $file = $c->req->upload('file');
    my $filename = File::Spec->catfile( $temp_dir, $file->filename );
    $file->move_to($filename);

    my ($suffix) = $file->filename =~ /\.([^\.]+)$/;
    $suffix = lc $suffix;
    $suffix = 'jpeg' if $suffix eq 'jpg';

    ( $filename, $suffix );
};

get '/' => sub {
    my $c = shift;
    $c->render( template => 'index' );
};

post 'scale' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $width  = $c->param('width');
    my $height = $c->param('height');

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->scale( width => $width, height => $height );

    $c->render( data => $blob, format => $suffix );
};

post 'crop_rectangle' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $left = $c->param('left') || 0;
    my $top  = $c->param('top')  || 0;
    my $width  = $c->param('width');
    my $height = $c->param('height');

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->crop_rectangle(
        left   => $left,
        top    => $top,
        width  => $width,
        height => $height,
    );

    $c->render( data => $blob, format => $suffix );
};

post 'flip_horizontal' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->flip_hozontal;

    $c->render( data => $blob, format => $suffix );
};

post 'flip_vertical' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->flip_vertical;

    $c->render( data => $blob, format => $suffix );
};

post 'rotate' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $degrees = $c->param('degrees');
    $degrees %= 360;

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->rotate( degrees => $degrees );

    $c->render( data => $blob, format => $suffix );
};

post 'convert' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $type = $c->param('type');

    my $driver = RemoteImageDriver::Imager->new( $filename, $suffix );
    my $blob = $driver->convert( type => $type );

    $c->render( data => $blob, format => $type );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
