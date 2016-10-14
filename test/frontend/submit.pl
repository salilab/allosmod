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
    my ($pack, $name) = @_;
    my $fv = ++$FH . $name;
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
    use_ok('allosmod');
}

my $t = new saliweb::Test('allosmod');

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
    $cgi->param('thermodyn_nruns', '3');
    $cgi->param('multiconf_mdtemp', '300');
    $cgi->param('thermodyn_mdtemp', '300');
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
    return $self;
}

# Check get_submit_page
{
    my $self = get_submit_frontend($t);
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");
    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_submit_page with ligand binding option
{
    my $self = get_submit_frontend($t);
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

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
    my $self = get_submit_frontend($t);
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

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
#
# Check get_submit_page with model glycosylation option, sample sugars
{
    my $self = get_submit_frontend($t);
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

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

    $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_nruns', '110');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num models for glyc";
    like($@, qr/number of models for glyc/, "exception message");

    $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_num_opt_steps', '11');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num steps for glyc";
    like($@, qr/number of models for glyc/, "exception message");

    $self = get_submit_frontend($t);
    $self->cgi->param('thermodyn_nruns', '101');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num of thermodyn runs";
    like($@, qr/sensible number of runs/, "exception message");

    $self = get_submit_frontend($t);
    $self->cgi->param('thermodyn_mdtemp', 'garbage');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad thermodyn temp";
    like($@, qr/sensible MD temperature for probable/, "exception message");

    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_alignment, batch job, empty file
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    $cgi->param('pdbcode', ());
    $cgi->param('uploaded_file', ());

    ok(open(FH, "> foo.zip"), "Open foo.zip");
    ok(close(FH), "Close foo.zip");
    open(FH, "foo.zip");

    $cgi->param('zip', \*FH);
    my ($aln, $job) = $self->get_alignment();
    is($aln, undef);
    is($job, undef);

    chdir('/') # Allow the temporary directory to be deleted
}

# Check get_alignment, batch job, non-empty file
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    $cgi->param('pdbcode', ());
    $cgi->param('uploaded_file', ());

    ok(open(FH, "> foo.zip"), "Open foo.zip");
    print FH "garbage";
    ok(close(FH), "Close foo.zip");
    open(FH, "foo.zip");

    $cgi->param('zip', \*FH);
    my ($aln, $job) = $self->get_alignment();
    is($aln, "X");

    ok(open(FH, $job->directory . "/input.zip"), "Open input.zip");
    is(<FH>, "garbage");
    close(FH);

    ok(open(FH, $job->directory . "/list"), "Open list");
    is(<FH>, "XX\n");
    close(FH);

    chdir('/') # Allow the temporary directory to be deleted
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

    $cgi->param('sequence', 'ACGV');
    $cgi->param('pdbcode', ());
    $cgi->param('uploaded_file', (TestFh->new('test.pdb')));

    my ($aln, $job) = $self->get_alignment();
    is($aln, "dummy alignment");

    chdir('/') # Allow the temporary directory to be deleted
}
