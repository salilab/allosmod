#!/usr/bin/perl -w

# A file handle object that behaves similarly to those returned by CGI's
# upload() method
package TestFh;
use Fcntl;
use overload
    '""' => \&asString;

$FH='fh00000';

sub DESTROY {
    my $self = shift;
    close $self;
}

sub asString {
    my $self = shift;
    # get rid of package name
    (my $i = $$self) =~ s/^\*(\w+::fh\d{5})+//;
    $i =~ s/%(..)/ chr(hex($1)) /eg;
    return $i;
}

sub new {
    my ($pack, $name, $reported_name) = @_;
    if (not defined $reported_name) {
        $reported_name = $name;
    }
    my $fv = ++$FH . $reported_name;
    my $ref = \*{"TestFh::$fv"};
    sysopen($ref, $name, Fcntl::O_RDWR(), 0600) || die "could not open: $!";
    return bless $ref, $pack;
}

package main;

use saliweb::Test;
use Test::More 'no_plan';
use File::Temp;
use Test::Exception;

BEGIN {
    use_ok('allosmod_foxs');
}

my $t = new saliweb::Test('allosmod_foxs');

# Check job submission

sub get_submit_frontend {
    my ($t) = @_;
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    $self->{config}->{allosmod}->{script_directory} = "/bin/true ";

    $cgi->param('jobname', 'test');
    $cgi->param('alignment', 'testali.ali');
    $cgi->param('ligandmod_rAS', '3');
    $cgi->param('glycmod_nruns', '10');
    $cgi->param('glycmod_num_opt_steps', '1');
    $cgi->param('advancedopt', '');
    $cgi->param('multiconf_mdtemp', '300');
    $cgi->param('multiconf_nruns', '10');
    $cgi->param('rareconf_nruns', '3');
    $cgi->param('rareconf_mdtemp', 'scan');
    $cgi->param('rareconf_cdencutoff', '3.5');
    $cgi->param('rareconf_locrig', '0');
    $cgi->param('rareconf_break', '0');
    $cgi->param('addbond_indices', '');
    $cgi->param('addupper_indices', '');
    $cgi->param('addlower_indices', '');
    $cgi->param('sampletype', 'rareconf');

    ok(open(FH, "> saxs.profile"), "Open saxs.profile");
    print FH "0 0 0\n";
    ok(close(FH), "Close saxs.profile");
    open(FH, "saxs.profile");

    $cgi->param('saxs_profile', \*FH);
    $cgi->param('comparativemod_nruns', '10');
    $cgi->param('saxs_qmax', '0.5');
    $cgi->param('saxs_psize', '500');
    $cgi->param('jobemail', '');
    return $self;
}

# Check get_submit_page
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_submit_page with ligand binding option
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    ok(open(FH, "> ligand.file"), "Open ligand.file");
    print FH "garbage\n";
    ok(close(FH), "Close ligand.file");
    open(FH, "ligand.file");

    $self->cgi->param('advancedopt', 'ligandmod');
    $self->cgi->param('ligandmod_ligfile', \*FH);
    $self->cgi->param('ligandmod_ligpdb', 'lig.pdb');
    $self->cgi->param('ligandmod_aspdb', 'as.pdb');

    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_submit_page with model glycosylation option, add sugars
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");
    my $self = get_submit_frontend($t);

    ok(open(FH, "> glyc.file"), "Open glyc.file");
    print FH "garbage\n";
    ok(close(FH), "Close glyc.file");
    open(FH, "glyc.file");

    $self->cgi->param('advancedopt', 'glycmod');
    $self->cgi->param('glycmodopt', 'option1');
    $self->cgi->param('glycmod_flexible_sites', 'on');
    $self->cgi->param('glycmod_input', \*FH);

    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_submit_page with model glycosylation option, sample sugars
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");
    my $self = get_submit_frontend($t);

    ok(open(FH, "> glyc.file"), "Open glyc.file");
    print FH "garbage\n";
    ok(close(FH), "Close glyc.file");
    open(FH, "glyc.file");

    $self->cgi->param('advancedopt', 'glycmod');
    $self->cgi->param('glycmodopt', 'option2');
    $self->cgi->param('glycmod_python', \*FH);

    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check bad options to get_submit_page
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    $self->cgi->param('ligandmod_rAS', 'garbage');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad radius";
    like($@, qr/Please provide a sensible radius/, "exception message");
    chdir('/') # Allow the temporary directory to be deleted
}

{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_nruns', '110');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num models for glyc";
    like($@, qr/number of models for glyc/, "exception message");
    chdir('/') # Allow the temporary directory to be deleted
}

{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_num_opt_steps', '11');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num steps for glyc";
    like($@, qr/number of models for glyc/, "exception message");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_alignment, empty sequence
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    $cgi->param("sequence", "    ");
    throws_ok { $self->get_alignment() }
              saliweb::frontend::InputValidationError,
              "no sequence provided";
    like($@, qr/Please provide sequence/);
    chdir('/');
}

# Check get_alignment, no PDB codes
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    $cgi->param("sequence", "CGV");
    $cgi->param("pdbcode", ());
    $cgi->param("uploaded_file", ());

    throws_ok { $self->get_alignment() }
              saliweb::frontend::InputValidationError,
              "no PDB code";
    like($@, qr/Please provide PDB code/);
    chdir('/');
}

# Check get_alignment, uploaded file
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    # Make dummy alignment so we don't have to run get_MULTsi20b.sh script
    $self->{config}->{allosmod}->{script_directory} = "/bin/true ";
    ok(open(FH, "> incoming/align.ali"), "Open align.ali");
    print FH "dummy alignment";
    ok(close(FH), "Close align.ali");

    ok(open(FH, "> test.pdb"), "Open test.pdb");
    print FH "garbage";
    ok(close(FH), "Close test.pdb");

    $cgi->param('jobemail', '');
    $cgi->param('sequence', 'ACGV');
    $cgi->param('pdbcode', ());
    $cgi->param('uploaded_file', (TestFh->new('test.pdb',
                                              '../../foo bar&;baz')));

    my ($aln, $job) = $self->get_alignment();
    is($aln, "dummy alignment");

    ok(open(FH, $job->directory . "/list"), "Open list");
    is(<FH>, "foobarbaz\n");
    close(FH);

    chdir('/') # Allow the temporary directory to be deleted
}
