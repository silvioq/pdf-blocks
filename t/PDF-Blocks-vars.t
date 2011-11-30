use Test::More tests => 3;
BEGIN { use_ok('PDF::Blocks') };

my $block;


# Testing var in block
$block = PDF::Blocks->new;
my $ret;
$block->block( 'name', 100, sub{ 
    my $self = shift;
    $ret = $self->var( 'myvar' );
});
$block->var( 'myvar', 12 );
ok( !$ret );
$block->print_block( 'name' );
is( $ret, 12 );


1;
