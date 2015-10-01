use Mojolicious::Lite;

use File::Spec;
use File::Temp qw/ tempfile tempdir /;
use Imager;

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

    my $imager = Imager->new;
    $imager->read( file => $filename );

    $imager = $imager->scale(
        xpixels => $width,
        ypixels => $height,
        type    => 'nonprop',
    );

    my $blob;
    $imager->write( data => \$blob, type => $suffix );

    $c->render( data => $blob, format => $suffix );
};

post 'crop_rectangle' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $left = $c->param('left') || 0;
    my $top  = $c->param('top')  || 0;
    my $width  = $c->param('width');
    my $height = $c->param('height');

    my $imager = Imager->new;
    $imager->read( file => $filename );

    $imager = $imager->crop(
        left   => $left,
        top    => $top,
        width  => $width,
        height => $height,
    );

    my $blob;
    $imager->write( data => \$blob, type => $suffix );

    $c->render( data => $blob, format => $suffix );
};

post 'flip_horizontal' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $imager = Imager->new;
    $imager->read( file => $filename );

    $imager->flip( dir => 'h' );

    my $blob;
    $imager->write( data => \$blob, type => $suffix );

    $c->render( data => $blob, format => $suffix );
};

post 'flip_vertical' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $imager = Imager->new;
    $imager->read( file => $filename );

    $imager->flip( dir => 'v' );

    my $blob;
    $imager->write( data => \$blob, type => $suffix );

    $c->render( data => $blob, format => $suffix );
};

post 'rotate' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $degrees = $c->param('degrees');
    $degrees %= 360;

    my $imager = Imager->new;
    $imager->read( file => $filename );

    $imager = $imager->rotate( right => $degrees );

    my $blob;
    $imager->write( data => \$blob, type => $suffix );

    $c->render( data => $blob, format => $suffix );
};

post 'convert' => sub {
    my $c = shift;
    my ( $filename, $suffix ) = $c->upload_file;

    my $type = $c->param('type');

    my $imager = Imager->new;
    $imager->read( file => $filename );

    my $blob;
    $imager->write( data => \$blob, type => $type );

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
