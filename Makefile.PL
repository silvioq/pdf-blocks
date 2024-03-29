use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDF::Blocks',
    VERSION_FROM      => 'lib/PDF/Blocks.pm', # finds $VERSION
    PREREQ_PM         => {
      'PDF::API2' => '2.019'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PDF/Blocks.pm', # retrieve abstract from module
       AUTHOR         => 'Silvio <silvio@>') : ()),
);
