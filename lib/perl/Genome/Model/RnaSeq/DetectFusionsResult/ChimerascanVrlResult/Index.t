#!/usr/bin/env genome-perl
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above 'Genome';
use Test::More;
use_ok('Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanVrlResult::Index');

my $chimerascan_version = '0.4.6';
my $picard_version = 1.82;

my $data_dir = $ENV{GENOME_TEST_INPUTS}."/Genome-Model-RnaSeq-DetectFusionsResult-ChimerascanVrlResult-Index/v2";
my $annotation_genepred = File::Spec->join($data_dir, '106942997-all_sequences.genepred');
diag "Test data located at: $data_dir";

my $reference_model = Genome::Model::ImportedReferenceSequence->create(
    name => '1 chr test model',
    subject => Genome::Taxon->get(name => 'human'),
    processing_profile => Genome::ProcessingProfile->get(name => 'chromosome-fastas'),
);

my $reference_build = Genome::Model::Build::ImportedReferenceSequence->create(
    model => $reference_model,
    fasta_file => $data_dir . "/all_sequences.fa",
    data_directory => $data_dir,
    version => '37'
);

my $annotation_model = Genome::Model::ImportedAnnotation->create(
    name => '1 chr test annotation',
    subject => $reference_model->subject,
    processing_profile => Genome::ProcessingProfile->get(name => 'imported-annotation.ensembl'),
    reference_sequence => $reference_build,
);

my $annotation_build = Genome::Model::Build::ImportedAnnotation->__define__(
    version => 'v1',
    model => $annotation_model,
    reference_sequence => $reference_build,
    data_directory => '/gscmnt/gc8002/info/model_data/2772828715/build125092315', #65_37j_v6
);
no warnings qw(redefine);
*Genome::Model::Build::ImportedAnnotation::annotation_file= sub { return 'test_filename.gtf' };

#hack to shorten results
my $tx_sub = $annotation_build->can('transcript_iterator');
*Genome::Model::Build::ImportedAnnotation::transcript_iterator = sub {
    my $self = shift;
    my %p = @_;
    $p{chrom_name} = 'GL000191.1';
    $self->warning_message('Transcript Iterator hardcoded to chromosome ' . $p{chrom_name} . ' for test.');
    return $tx_sub->($self, %p);
};
*Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanVrlResult::Index::_convert_gtf_to_genepred = sub {
    my $self = shift;
    my $gene_file = $self->gene_file;
    Genome::Sys->shellcmd(cmd => "cp $annotation_genepred $gene_file",
        input_files => [$annotation_genepred],
        output_files => [$gene_file],
    );
};
use warnings qw(redefine);

my $result = Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanVrlResult::Index->get_or_create(
    version => $chimerascan_version,
    bowtie_version => "0.12.5",
    reference_build => $reference_build,
    annotation_build => $annotation_build,
    picard_version => $picard_version,
);

isa_ok($result, "Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanVrlResult::Index");

done_testing();

1;
