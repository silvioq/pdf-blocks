package  PDF::Blocks::Print;
# vi: set cin sw=2:
#
use strict;
use warnings;
require Exporter;
use  PDF::API2;

sub  new{
  my $class = shift;
  my $def = shift;
  my $self = {
    def => $def,
  };
  bless $self;
  return $self;
}

sub  set_skip($$){
  my $self = shift;
  $self->{skip} = shift;
  $self->{advance} = shift;
  $self->_check_for_newpage;
}

sub  eject{
  my $self = shift;
  $self->{skip} = 0;
  $self->_check_for_newpage; # Check for first page.
  $self->_run_footer;
  delete $self->{_curr_y};
}

sub  skip{
  my $self = shift;
  $self->{_curr_y} += $self->{skip} if $self->{advance};
}


sub  _pdf{
  my $self = shift;
  return  $self->{pdf} if $self->{pdf};
  my $pdf = PDF::API2->new;
  if( ref( $self->{def}->mediabox ) eq "ARRAY" ){
    $pdf->mediabox( @{$self->{def}->mediabox} );
  } else {
    $pdf->mediabox( $self->{def}->mediabox );
  }
  $self->{pdf} = $pdf;
  $self->{page} = $pdf->page;
  $self->{number} = 1;
  my($llx, $lly, $urx, $ury) = $self->{page}->get_mediabox;
  my %sizes = (
    lx => $llx, ly => $lly, rx => $urx, ry => $ury,
    mb => 25, mt => 25, ml => 25, mr => 25 # margins
  );
  foreach( keys %sizes ){
    $self->{$_} = $sizes{$_};
  }
}

sub  _page{ shift->{page} || die( 'Can not use page now' ) }
sub  _gfx{
  my $self = shift;
  return $self->{gfx} if $self->{gfx};
  return $self->{gfx} = $self->_page->gfx;
}
sub  _text{
  my $self = shift;
  return $self->{text} if $self->{text};
  return $self->{text} = $self->_page->text;
}

sub  _new_page{
  my $self = shift;
  my $pdf = $self->_pdf;
  $self->{page} = $pdf->page;
  delete $self->{text};
  delete $self->{gfx};
  $self->{number} += 1;
}

sub  _check_for_newpage{
  my $self = shift;
  my $pdf = $self->_pdf;
  if( !$self->{_curr_y} ){ 
    # First page
    $self->{_curr_y} = $self->{ry} - $self->{mt};
    $self->_run_header;
  } else {
    if( $self->{_curr_y} - $self->{skip} < $self->{mb} ){
      $self->_run_footer;
      $self->{_curr_y} = $self->{ry} - $self->{mt};
      $self->_new_page;
      $self->_run_header;
    }
  }
}

sub  _run_header{
  my $self = shift;
  $self->_run_blocks( @{$self->{def}->{header}} ) if $self->{def}->{header};
}
sub  _run_footer{
  my $self = shift;
  my $fs = $self->_footer_size;
  $self->{_curr_y} = $self->{ry} - $self->{mt} - $fs;
  $self->_run_blocks( @{$self->{def}->{footer}} ) if $self->{def}->{footer};
}

sub  _footer_size{
  return shift->{def}->footer_size;
}

sub _run_blocks{
  my $self = shift;
  foreach my $b ( @_ ){
    my  $advance = $self->{advance};
    my  $skip    = $self->{skip};
    $self->{def}->print_block( $b->{name}, { advance => $b->{advance} } );
    $self->{advance} = $advance;
    $self->{skip}    = $skip;
  }
}

sub  _resolve_font{
  my( $self, $font_name, $bold, $italic ) = @_;
  $font_name = lc( $font_name );
  if( $font_name =~ /^times.*/ ){
    if( $bold && $italic ){
      return $self->_pdf->corefont( 'Times-BoldItalic' );
    } elsif( $bold ){
      return $self->_pdf->corefont( 'Times-Bold' );
    } elsif( $italic ){
      return $self->_pdf->corefont( 'Times-Italic' );
    } else {
      return $self->_pdf->corefont( 'Times-Roman' );
    }
  } elsif( $font_name eq 'courier' ){
    if( $bold && $italic ){
      return $self->_pdf->corefont( 'Courier-BoldOblique' );
    } elsif( $bold ){
      return $self->_pdf->corefont( 'Courier-Bold' );
    } elsif( $italic ){
      return $self->_pdf->corefont( 'Courier-Oblique' );
    } else {
      return $self->_pdf->corefont( 'Courier' );
    }
  } elsif( $font_name eq 'helvetica' ){
    if( $bold && $italic ){
      return $self->_pdf->corefont( 'Helvetica-BoldOblique' );
    } elsif( $bold ){
      return $self->_pdf->corefont( 'Helvetica-Bold' );
    } elsif( $italic ){
      return $self->_pdf->corefont( 'Helvetica-Oblique' );
    } else {
      return $self->_pdf->corefont( 'Helvetica' );
    }
  } elsif( $font_name eq 'georgia' ){
    if( $bold && $italic ){
      return $self->_pdf->corefont( 'Georgia,BoldOblique' );
    } elsif( $bold ){
      return $self->_pdf->corefont( 'Georgia,Bold' );
    } elsif( $italic ){
      return $self->_pdf->corefont( 'Georgia,Oblique' );
    } else {
      return $self->_pdf->corefont( 'Georgia' );
    }
  } elsif( ( $font_name eq 'arial' ) || ( $font_name eq 'verdana' ) ){
    if( $bold && $italic ){
      return $self->_pdf->corefont( 'Verdana,BoldOblique' );
    } elsif( $bold ){
      return $self->_pdf->corefont( 'Verdana,Bold' );
    } elsif( $italic ){
      return $self->_pdf->corefont( 'Verdana,Oblique' );
    } else {
      return $self->_pdf->corefont( 'Verdana' );
    }
  } elsif( $font_name eq 'symbol' ){
    return $self->_pdf->corefont( 'Symbol' );
  }
  die( "Can not determine core fonts" );
}

# #------------------------------------------- Public functions ----------------------------------
sub  var{
  my $self = shift;
  $self->{def}->var( shift );
}

sub  line($$$$){
  my( $self, $x1, $y1, $x2, $y2 ) = @_;
  $self->_gfx->move( $x1 + $self->{mt} + $self->{lx},
      $self->{_curr_y} - $y1 );
  $self->_gfx->line( $x2 + $self->{mt} + $self->{lx},
      $self->{_curr_y} - $y2 );
  $self->_gfx->stroke;
  return $self;
}
sub  rect($$$$$){
  my( $self, $x1, $y1, $x2, $y2, $fill ) = @_;
  $self->_gfx->rectxy( $x1 + $self->{mt} + $self->{lx}, $self->{_curr_y} - $y1,
      $x2 + $self->{mt} + $self->{lx}, $self->{_curr_y} - $y2 );
  if( $fill ){
    $self->_gfx->fill;
  } else {
    $self->_gfx->stroke;
  }
  return $self;
}

# x1, y1, x2, y2, text, font_name, font_size, align, bold, italic
sub  cell($$$$$$$$$$){
  my( $self, $x1, $y1, $x2, $y2, $text, $font_name, $font_size, $align, $bold, $italic ) = @_;
  # Set the font
  my $font = $self->_resolve_font( $font_name || 'Helvetica', $bold, $italic );
  $font_size = 12 unless $font_size;
  my $lead = $font_size * 1.2;
  if( $lead > $y2 - $y1 ){
    $y2 = $y1 + $lead + 0.5;
  }
  $self->_text->font( $font, $font_size );
  text_block( $self->_text, $text,
    -x => $x1 + $self->{mt} + $self->{lx},
    -y => $self->{_curr_y} - $y1 - $font_size,
    -w => $x2 - $x1, -h => $y2 - $y1,
    -lead => $lead,
    -align => $align || 'left' );
  return  $self;
}

=begin
 text_block() is © Rick Measham, 2004-2007. The latest version can be found in the tutorial located at http://rick.measham.id.au/pdf-api2/
($width_of_last_line, $ypos_of_last_line, $left_over_text) = text_block(

    $text_handler_from_page,
    $text_to_place,
    -x        => $left_edge_of_block,

    -y        => $baseline_of_first_line,
    -w        => $width_of_block,

    -h        => $height_of_block,
   [-lead     => $font_size * 1.2 | $distance_between_lines,]
   [-parspace => 0 | $extra_distance_between_paragraphs,]
   [-align    => "left|right|center|justify|fulljustify",]
   [-hang     => $optional_hanging_indent,]

);
=cut

sub text_block {

    my $text_object = shift;
    my $text        = shift;

    my %arg = @_;

    # Get the text in paragraphs
    my @paragraphs = split( /\n/, $text );

    # calculate width of all words
    my $space_width = $text_object->advancewidth(' ');

    my @words = split( /\s+/, $text );
    my %width = ();
    foreach (@words) {
        next if exists $width{$_};
        $width{$_} = $text_object->advancewidth($_);
    }

    my $ypos = $arg{'-y'};
    my $endw;
    my @paragraph = split( / /, shift(@paragraphs) );

    my $first_line      = 1;
    my $first_paragraph = 1;

    # while we can add another line

    while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {

        unless (@paragraph) {
            last unless scalar @paragraphs;

            @paragraph = split( / /, shift(@paragraphs) );

            $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            last unless $ypos >= $arg{'-y'} - $arg{'-h'};

            $first_line      = 1;
            $first_paragraph = 0;
        }

        my $xpos = $arg{'-x'};

        # while there's room on the line, add another word
        my @line = ();

        my $line_width = 0;
        if ( $first_line && exists $arg{'-hang'} ) {

            my $hang_width = $text_object->advancewidth( $arg{'-hang'} );

            $text_object->translate( $xpos, $ypos );
            $text_object->text( $arg{'-hang'} );

            $xpos       += $hang_width;
            $line_width += $hang_width;
            $arg{'-indent'} += $hang_width if $first_paragraph;

        }
        elsif ( $first_line && exists $arg{'-flindent'} ) {

            $xpos       += $arg{'-flindent'};
            $line_width += $arg{'-flindent'};

        }
        elsif ( $first_paragraph && exists $arg{'-fpindent'} ) {

            $xpos       += $arg{'-fpindent'};
            $line_width += $arg{'-fpindent'};

        }
        elsif ( exists $arg{'-indent'} ) {

            $xpos       += $arg{'-indent'};
            $line_width += $arg{'-indent'};

        }

        while ( @paragraph
            and $line_width + ( scalar(@line) * $space_width ) +
            $width{ $paragraph[0] } < $arg{'-w'} )
        {

            $line_width += $width{ $paragraph[0] };
            push( @line, shift(@paragraph) );

        }

        # calculate the space width
        my ( $wordspace, $align );
        if ( $arg{'-align'} eq 'fulljustify'
            or ( $arg{'-align'} eq 'justify' and @paragraph ) )
        {

            if ( scalar(@line) == 1 ) {
                @line = split( //, $line[0] );

            }
            $wordspace = ( $arg{'-w'} - $line_width ) / ( scalar(@line) - 1 );

            $align = 'justify';
        }
        else {
            $align = ( $arg{'-align'} eq 'justify' ) ? 'left' : $arg{'-align'};

            $wordspace = $space_width;
        }
        $line_width += $wordspace * ( scalar(@line) - 1 );

        if ( $align eq 'justify' ) {
            foreach my $word (@line) {

                $text_object->translate( $xpos, $ypos );
                $text_object->text($word);

                $xpos += ( $width{$word} + $wordspace ) if (@line);

            }
            $endw = $arg{'-w'};
        }
        else {

            # calculate the left hand position of the line
            if ( $align eq 'right' ) {
                $xpos += $arg{'-w'} - $line_width;

            }
            elsif ( $align eq 'center' ) {
                $xpos += ( $arg{'-w'} / 2 ) - ( $line_width / 2 );

            }

            # render the line
            $text_object->translate( $xpos, $ypos );

            $endw = $text_object->text( join( ' ', @line ) );

        }
        $ypos -= $arg{'-lead'};
        $first_line = 0;

    }
    unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);

    return ( $endw, $ypos, join( "\n", @paragraphs ) )

}

1;
