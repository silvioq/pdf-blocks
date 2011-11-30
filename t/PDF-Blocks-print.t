# vi: set cin sw=2:
use Test::More tests => 6;
BEGIN { use_ok('PDF::Blocks') };

my $block;


# Testing line in block
$block = PDF::Blocks->new;
my $ret;
$block->block( 'line', 100, sub{ 
    shift->line( 0,0,500,100);
});
$block->block( 'rect', 100, sub{ 
    shift->rect( 0,0,500,100);
});
$block->block( 'cell', 100, sub{ 
    shift->cell( 0,0,100,12, "Hello word", "Helvetica", 12, "left", 0, 0 );
});

$block->print_block( "line" );
$block->print_block( "rect" );
$block->print_block( "cell" );

my $s;
ok( $s = $block->end );
ok( length( $s ) > 4200 );
ok( length( $s ) < 4300 );
is( substr( $s, 0, 4 ), "%PDF" );

$block->print_block( "line" );
$block->print_block( "rect" );
$block->print_block( "cell" );
$block->end( "temp.pdf" );

if( -e "temp.pdf" ){
  ok( 1, "File exists" );
} else {
  ok( 0, "File exists" );
}

unlink( "temp.pdf" ) unless $ENV{SEE_PDF};

