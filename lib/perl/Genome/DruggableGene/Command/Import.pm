package Genome::DruggableGene::Command::Import;

use strict;
use warnings;

use Genome;

class Genome::DruggableGene::Command::Import {
    is => 'Genome::Command::Base',
    has => [],
};

sub help_brief {
    'Import druggable gene datasource into the database'
}

sub help_synopsis {
    return <<EOS
genome druggable-gene import ...
EOS
}

1;
