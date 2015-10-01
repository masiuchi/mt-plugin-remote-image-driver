package MT::Image::Remote;
use strict;
use warnings;
use base qw( MT::Image );

use File::Temp qw/ tempfile /;
use Image::Size;

use MT;
use MT::FileMgr;

sub load_driver {
    my $image = shift;
    my $ua    = MT->new_ua;
    $ua->ssl_opts( verify_hostname => 1 );
    my $res = $ua->get( MT->config->RemoteImageDriver );
    unless ( $res->is_success ) {
        return $image->error(
            MT->component('RemoteImageDriver')->translate(
                'Cannot load RemoteImageDriver: [_1]',
                $res->status_line
            )
        );
    }
    1;
}

sub init {
    my $image = shift;
    my %param = @_;

    $image->SUPER::init(%param);

    if ( ( !defined $param{Type} ) && ( my $file = $param{Filename} ) ) {
        ( my $ext = $file ) =~ s/.*\.//;
        $param{Type} = lc $ext;
    }
    $image->{type} = $param{Type};

    my $fmgr = MT::FileMgr->new('Local');
    if ( my $file = $param{Filename} ) {
        $image->{file} = $param{Filename};
        $image->{data} = $fmgr->get_data( $file, 'upload' );
    }
    elsif ( my $blob = $param{Data} ) {
        my ( $fh, $tempfile ) = tempfile( SUFFIX => '.' . $image->{type} );
        close $fh;
        $image->{file} = $tempfile;
        $image->{data} = $blob;
        $fmgr->put_data( $blob, $tempfile, 'upload' );
    }

    ( $image->{width}, $image->{height} ) = imgsize( $image->{file} );

    $image;
}

sub blob {
    my $image = shift;
    $image->{data};
}

sub scale {
    my $image = shift;
    my ( $w, $h ) = $image->get_dimensions(@_);
    $image->{blob} = $image->post(
        endpoint => '/scale',
        width    => $w,
        height   => $h,
    );
    @$image{qw/width height/} = ( $w, $h );
    wantarray ? ( $image->{blob}, $w, $h ) : $image->{blob};
}

sub crop_rectangle {
    my $image = shift;
    my %param = @_;
    my ( $width, $height, $x, $y ) = @param{qw( Width Height X Y )};

    $image->{blob} = $image->post(
        endpoint => '/crop_rectangle',
        left     => $x,
        top      => $y,
        width    => $width,
        height   => $height,
    );

    $image->{width}  = $width;
    $image->{height} = $height;

    wantarray ? ( $image->{blob}, $width, $height ) : $image->{blob};
}

sub flipHorizontal {
    my $image = shift;
    $image->{blob} = $image->post( endpoint => '/flip_horizontal' );
    wantarray
        ? ( $image->{blob}, @$image{qw( width height )} )
        : $image->{blob};
}

sub flipVertical {
    my $image = shift;
    $image->{blob} = $image->post( endpoint => '/flip_vertical' );
    wantarray
        ? ( $image->{blob}, @$image{qw( width height )} )
        : $image->{blob};
}

sub rotate {
    my $image = shift;
    my ( $degrees, $w, $h ) = $image->get_degrees(@_);
    $image->{blob} = $image->post(
        endpoint => '/rotate',
        degrees  => $degrees,
    );
    wantarray
        ? ( $image->{blob}, $w, $h )
        : $image->{blob};
}

sub convert {
    my $image = shift;
    my %param = @_;
    $image->{blob} = $image->post(
        endpoint => '/convert',
        type     => $param{Type},
    );
}

sub post {
    my ( $image, %param ) = @_;
    my $endpoint = delete $param{endpoint};

    my $ua = MT->new_ua;
    $ua->ssl_opts( verify_hostname => 1 );

    my $res = $ua->post(
        MT->config->RemoteImageDriver . $endpoint,
        'content-type' => 'form-data',
        Content        => {
            file => [ $image->{file} ],
            %param,
        },
    );
    $res->content;
}

1;

