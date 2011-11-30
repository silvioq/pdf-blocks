package PDF::Blocks;
# vi: set cin sw=2:

use 5.010001;
use strict;
use warnings;

require Exporter;
use  PDF::Blocks::Dummy;
use  PDF::Blocks::Print;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PDF::Blocks ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	new block  header  footer
);

our $VERSION = '0.01';

sub  new{
  my $self = {
    blocks => {},
    header => [],
    footer => [],
    vars   => {},
    mediabox => [ 842, 595 ], # A4-Landscape
  };
  bless $self;
  return $self;
};

sub  block{
  my( $self, $name, $skip, $code ) = @_;
  die "Must indicate code reference" unless ref($code) eq "CODE";
  $self->{blocks}->{$name} = { skip => $skip, code => $code };
  eval{
    $code->('PDF::Blocks::Dummy');
  };
  die( "Incorrect syntax: $@" ) if $@;
}

sub  header{
  my $self = shift;
  my $name;
  my $adv ;
  if( scalar(@_) == 1 && ref( $_[0] ) eq "HASH" ){
    my $def = shift;
    die( "Incorrect header definition, must indicate name" ) unless $def->{name};
    $name = $def->{name};
    $adv  = $def->{advance};
  } elsif( scalar(@_) == 1 ){
    $name = shift;
    $adv  = 1;
  } elsif( scalar(@_) == 2 ){
    $name = shift;
    $adv  = shift;
  } else {
    die( "Incorrect header definition, see documentation" );
  }
  push @{$self->{header}}, { name => $name, advance => $adv };
}

sub  footer{
  my $self = shift;
  my $name;
  my $adv ;
  if( scalar(@_) == 1 && ref( $_[0] ) eq "HASH" ){
    my $def = shift;
    die( "Incorrect footer definition, must indicate name" ) unless $def->{name};
    $name = $def->{name};
    $adv  = $def->{advance};
  } elsif( scalar(@_) == 1 ){
    $name = shift;
    $adv  = 1;
  } elsif( scalar(@_) == 2 ){
    $name = shift;
    $adv  = shift;
  } else {
    die( "Incorrect footer definition, see documentation" );
  }
  push @{$self->{footer}}, { name => $name, advance => $adv };
}

sub  var{
  my $self = shift;
  my $var  = shift;
  if( ref( $var ) eq 'HASH' ){
    foreach( keys( %{$var} ) ){
      $self->var( $_, $var->{$_} );
    }
    return 1;
  }
  if( scalar( @_ ) > 0 ){
    my $val = shift;
    return $self->{vars}->{$var} = $val;
  } else {
    return $self->{vars}->{$var};
  }
}

sub  mediabox{
  my $self = shift;
  if( @_ ){
    return $self->{mediabox} = shift;
  } else {
    return $self->{mediabox};
  }
}


sub  print_block{
  my( $self, $name, $options ) = @_;
  die( "Must indicate block name" ) unless $name;
  my $block = $self->{blocks}->{$name} ;
  die( "Block $name does not exists" ) unless $block;
  $self->{printer} = PDF::Blocks::Print->new( $self )
    if( !$self->{printer} );
  $options = {} unless $options;
  my $printer = $self->{printer};
  $printer->set_skip( $block->{skip}, $options->{advance} );
  $block->{code}->($printer);
  $printer->skip;
}

# Returns block size
sub  block_size{
  my( $self, $name ) = @_;
  my $block = $self->{blocks}->{$name} ;
  die( "Block $name does not exists" ) unless $block;
  return $block->{skip};
}

sub  footer_size{
  my $self = shift;
  return $self->{footer_size} if $self->{footer_size};
  my $fs = 0;
  foreach( @{$self->{footer}} ){
    next unless $_->{advance};
    $fs += $self->block_size( $_->{name} );
  }
  return $self->{_footer_size} = $fs;
}

sub  eject{
  my $self = shift;
  $self->{printer} = PDF::Blocks::Print::new( $self )
    if( !$self->{printer} );
  $self->{printer}->eject;
}

sub  end($){
  my $self = shift;
  my $file = shift;
  my $printer = $self->{printer};
  my $string ;
  die( "Can not end pdf without blocks" ) unless $printer;
  die( "Not pdf" ) unless $printer->_pdf;
  if( $file ){
    $printer->_pdf->saveas( $file ) ;
  } else {
    $string = $printer->_pdf->stringify;
  }
  delete $self->{printer};
  $printer->_pdf->end;
  return $string || 1;
}

1;


# Preloaded methods go here.

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PDF::Blocks - Perl extension for blah blah blah

=head1 SYNOPSIS

  use PDF::Blocks;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for PDF::Blocks, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

=over

=item block
This funcion defines a print block code

  $block->block( 'name', 200, sub{
      my $self = shift;
      $self->line( 0,0,100,0 );
      $self->rect( 0,0,100,10 );
      $self->cell( 0,0,100,12, "Hello test", "Arial", 12, "left", 0, 0 );
    });

=item header

This function adds some block (invoked by name) to every page header

  $pdf_blocks->header('block-name');

  $pdf_blocks->header( { name => 'block-name', advance => 0 } );

=item footer

This function adds some block (invoked by name) to every page footer

  $pdf_blocks->header('block-name');

=back


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Silvio, E<lt>silvio@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Silvio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
