#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::Exception;
use Test::More;
use Genome::File::Vcf::Entry;

my $pkg = "Genome::VariantReporting::Dbsnp::CafInterpreter";
use_ok($pkg);
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('interpreters', $pkg->name), $pkg);

subtest "one alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            caf => 0.3,
            max_alt_af => 0.3,
        }
    );
    my $entry = create_entry('[0.7,0.3,.]');
    is_deeply({$interpreter->interpret_entry($entry, ['C'])}, \%expected_return_values, "Entry gets interpreted correctly");
};

subtest "no caf" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            caf => undef,
            max_alt_af => undef,
        }
    );
    my $entry = create_entry();
    is_deeply({$interpreter->interpret_entry($entry, ['C'])}, \%expected_return_values, "Entry gets interpreted correctly");
};

subtest "two alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            caf => 0.3,
            max_alt_af => 0.3,
        },
        G => {
            caf => '.',
            max_alt_af => 0.3,
        },
    );
    my $entry = create_entry('[0.7,0.3,.]');
    is_deeply({$interpreter->interpret_entry($entry, ['C', 'G'])}, \%expected_return_values, "Entry gets interpreted correctly");
};

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=CAF,Number=.,Type=Float,Description="CAF">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
EOS
    my @lines = split("\n", $header_txt);
    my $header = Genome::File::Vcf::Header->create(lines => \@lines);
    return $header
}

sub create_entry {
    my $caf = shift;
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        'A',            # REF
        'C,G',          # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
    );
    if (defined $caf) {
        push @fields, "CAF=$caf";
    }

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}

done_testing;
